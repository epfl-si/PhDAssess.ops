package EPFL::Zeebe::Observability;
use Dancer2;
use Dancer::Exception qw(:all);

our $VERSION = '0.1';

register_exception ('EPFL::Zeebe::Observability::Snapshot::NotFound',
                    message_pattern => "invalid credentials : %s",
                   );

get '/' => sub {
    template 'index' => { 'title' => 'EPFL::Zeebe::Observability' };
};

get '/snapshots' => sub {
  use Data::Dumper;
  template 'directory' => {
    title => 'Snapshots',
    snapshots => [
      map { {name => $_->id , uri => "/snapshots/" . $_->id } }
          EPFL::Zeebe::Observability::Snapshot->all
    ]
  }
};

get '/snapshots/:snapshotid[StrMatch[qr{\d+-\d+-\d+}]]' => sub {
    my $id = route_parameters->get('snapshotid');
    my $snapshot = EPFL::Zeebe::Observability::Snapshot->load($id) or return (status 404);
    return $snapshot->id;
};

get '/perlinfo' => sub {
  return "<pre>$EPFL::Zeebe::Observability::Snapshot::datadir</pre>";
};


package EPFL::Zeebe::Observability::Snapshot;

use File::Find;

our $datadir = $ENV{ZEEBE_OBSERVABILITY_DATA_DIR} || "/usr/local/zeebe/data";

our $dirmatch = qr//;

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

sub snapshots_dir { "$datadir/raft-partition/partitions/1/snapshots" }

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
