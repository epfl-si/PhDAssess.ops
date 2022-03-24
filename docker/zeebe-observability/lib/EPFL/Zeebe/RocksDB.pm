package EPFL::Zeebe::RocksDB;

our $datadir = $ENV{ZEEBE_OBSERVABILITY_DATA_DIR} || "/usr/local/zeebe/data";

package EPFL::Zeebe::RocksDB::Snapshot;
use File::Find;

sub all {
  my ($class) = @_;
  my @all;
  find({
    no_chdir => 1,
    wanted => sub {
      warn $_;
      return unless -d && m[(?:^|/)(\d+-\d+-\d+-\d+)$];
      push @all, $class->load($1);
    }
  }, $class->snapshots_dir);
  @all;
}

sub snapshots_dir { "$EPFL::Zeebe::RocksDB::datadir/raft-partition/partitions/1/snapshots" }

sub load {
  my ($class, $id) = @_;
  warn "load($id)...\n";
  return unless -d (my $path = $class->snapshots_dir . "/$id");
  warn "load($id) succesful\n";
  bless {
    id => $id,
    path => $path
  }, $class;
}

sub id { shift->{id} }

1;
