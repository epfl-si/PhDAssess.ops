=head1 EPFL::Zeebe::RocksDB

This package contains a hierarchy of classes to model the RocksDB
instances that can be found in a Zeebe C<data> volume.

=cut

package EPFL::Zeebe::RocksDB;

use RocksDB;
use Data::MessagePack;
use ZeebeDB::Key;

our $datadir = $ENV{ZEEBE_OBSERVABILITY_DATA_DIR} || "/usr/local/zeebe/data";

sub absolute_path {
  my ($class, $relpath) = @_;
  return "$datadir/$relpath";
}

sub open {
  my ($class, $path) = @_;

  return unless -d (my $fullpath = $class->absolute_path($path));
  bless {
    path => $path,
    db => RocksDB->new($fullpath, { read_only => 1 })
  }, $class;
}

sub dump {
  my ($self) = @_;

  return $self->{dump} if $self->{dump};

  $self->{dump} = {};

  my $iter = $self->{db}->new_iterator->seek_to_first;
  while (my ($key, $value) = $iter->each) {
    eval { $value = Data::MessagePack->unpack($value) };

    my $walk = $self->{dump};
    my @keytoks = ZeebeDB::Key->parse($key);
    while(@keytoks > 1) {
      my $keytok = (shift @keytoks)->pretty;
      $walk->{$keytok} ||= {};
      $walk = $walk->{$keytok};
    }

    $walk->{(shift @keytoks)->pretty} = summarize_strings($value);
  }

  return $self->{dump};
}

sub summarize_strings {
  my $wat = shift;

  if (ref($wat) eq "HASH") {
    return { map { summarize_strings($_) } %$wat };
  } elsif (ref($wat) eq "ARRAY") {
    return [ map { summarize_strings($_) } @$wat ];
  } elsif (ref($wat)) {
    return $wat;
  }

  return ZeebeDB::Key::Tok::String->pretty($wat);
}

package EPFL::Zeebe::RocksDB::Snapshot;
use base qw(EPFL::Zeebe::RocksDB);
use File::Find;

our $snapshots_subdir = "raft-partition/partitions/1/snapshots";

sub all {
  my ($class) = @_;
  my @all;
  find({
    no_chdir => 1,
    wanted => sub {
      warn $_;
      return unless -d && m[(?:^|/)(\d+-\d+-\d+-\d+)$];
      push @all, $class->open($1);
    }
  }, $class->absolute_path($snapshots_subdir));
  @all;
}

sub open {
  my ($class, $id) = @_;
  return unless my $self = $class->SUPER::open("$snapshots_subdir/$id");
  $self->{id} = $id;
  return $self;
}

sub id { shift->{id} }

1;
