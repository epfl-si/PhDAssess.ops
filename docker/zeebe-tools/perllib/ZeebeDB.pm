=head1 NAME

ZeebeDB - Interface to a Zeebe RocksDB database and assorted items

=head1 DESCRIPTION

This thin wrapper around L<RocksDB> guarantees that at L</close> time,
the on-disk state is compatible with a Zeebe “cold” load (e.g. from a
snapshot). This means an up-to-date .checksum file. (Zeebe tolerates
RocksDB WAL files ending in .log)

=cut

package ZeebeDB;

use RocksDB;
use File::Find;
use File::Basename;
use Fcntl qw(:flock);

sub open {
  my ($class, $path, $open_options) = @_;
  my $self = bless {
    path => $path,
    # Lazy-open (no db =>) - Mostly for the ability to no-op test the
    # checksum business
    open_options => $open_options,
  }, $class;
  return $self;
}

sub readonly {
  shift->{open_options}->{read_only} = 1;
}

sub db {
  my ($self) = @_;
  if (! $self->{db}) {
    my @new_opts = $self->{path};
    push @new_opts, $self->{open_options} if $self->{open_options};
    $self->{db} = RocksDB->new(@new_opts);
  }
  return $self->{db};
}

sub put         {
  my ($self, $k, $v) = @_;
  $self->db->put($k, $v, { disableWAL => 1 });
}

sub delete         {
  my ($self, $k) = @_;
  $self->db->delete($k, { disableWAL => 1 });
}

sub new_iterator { shift->db->new_iterator(@_) }

=item close ()

Close the database, flushing any pending writes, and update its status
to Zeebe-compatible “cold” state.

=cut

sub close {
  my ($self) = @_;

  if ($self->{db}) {
    $self->{db}->flush();

    # Start close sequence...
    $self->{db} = undef;
    my $lockfile = "$self->{path}/LOCK";
    CORE::open(my $lockfd, "<", $lockfile)
      or die "open($lockfile): $!";
    # ... and join it.
    sleep 1 until flock($lockfd, LOCK_EX|LOCK_NB);

    # We don't want Java to see these:
    unlink($lockfile);
    unlink("$self->{path}/LOG");
  }

  my $checksum = new ZeebeDB::_Checksum($self->{path});
  find({
    no_chdir => 1,
    wanted => sub {
      next unless -f;
      $checksum->add($_);
    }
  }, $self->{path});
  $checksum->overwrite();
}

=head2 walk_column_family ($cf_name, $walker)

Call C<$walker> once per line in the column family C<$cf_name>.

C<$walker> will be called as

  $walker->($keyRaw, $value, @keyParts)


where

=over

=item C<$keyRaw>

is the raw (binary) key as seen by the RocksDB cursor

=item C<$value>

is the MessagePack-decoded value as a L<Data::MessagePack> object if the decoding was successful; or the raw value otherwise

=item C<@keyParts>

is whatever C<< ZeebeDB::Key->parse($keyRaw) >> returns

=back

=cut

sub walk_column_family {
  my ($self, $cf_name, $walker) = @_;
  $self->walk_column_family_raw($cf_name, sub {
                                  eval { $_[1] = Data::MessagePack->unpack($_[1]) };
                                  $walker->(@_);
                                });
}

=head2 walk_column_family_raw ($cf_name, $walker)

Like L</walk_column_family>, except the value is not decoded and is
still in binary form.

=cut

sub walk_column_family_raw {
  my ($self, $cf_name, $walker) = @_;
  my $iter = $self->db->new_iterator->seek_to_first;
  while (my ($key, $value) = $iter->each) {
    my ($cf, @key_toks) = ZeebeDB::Key->parse($key);
    next unless $cf->name eq $cf_name;
    $walker->($key, $value, $cf, @key_toks);
  }
}

package ZeebeDB::_Checksum;

use File::Basename;
use File::Slurp;
use Crypt::Rhash;

sub new {
  my ($class, $dir) = @_;
  $dir =~ s|/*$||;
  bless {
    path => "$dir.checksum",
    files => []
  }, $class;
}

sub add {
  my ($self, $path) = @_;
  push @{$self->{files}}, $path;
}

sub to_string {
  my ($self) = @_;

  my $mainmatter = "";
  my $combinedChecksum = new Crypt::Rhash(RHASH_CRC32C);

  foreach my $filename (sort @{$self->{files}}) {
    defined(my $bytes = read_file($filename, { binmode => ':raw' }))
      or die "read_file($filename): $!";
    my $basename = basename($filename);
    my $checksum = Crypt::Rhash->new(RHASH_CRC32C)->update($bytes)->final->hash_hex();
    $mainmatter .= <<"LINE";
$basename   $checksum
LINE

    $combinedChecksum->update($basename)->update($bytes);
  }

  chomp($mainmatter);
  return <<ALL_YOUR_CHECKSUM_ARE_BELONG_TO_US;
; This is an SFC checksum file for all files in the given directory.
; It has been doctored by Perl to fool Zeebe into loading it.
;
; combinedValue = ${\scalar($combinedChecksum->final->hash_hex)}
$mainmatter
ALL_YOUR_CHECKSUM_ARE_BELONG_TO_US
}

=item overwrite ()

Overwrite this ZeebeDB's checksum file.

We would rather move it to a C<foo.ORIG> backup file, but
unfortunately this causes a C<< java.lang.NumberFormatException >> in
C<< FileBasedSnapshotStore#collectSnapshot >>. Oh well.

=cut

sub overwrite {
  my ($self) = @_;
  write_file($self->{path}, $self->to_string);
}

1;
