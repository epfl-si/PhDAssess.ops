package EPFL::Zeebe::Observability;
use Dancer2;

use EPFL::Zeebe::RocksDB;

our $VERSION = '0.1';

sub a_404 {
  status 404;
  send_file '/404.html';
}

get '/' => sub {
    template 'index' => { 'title' => 'EPFL::Zeebe::Observability' };
};

any '/rocksdb' => sub { redirect '/rocksdb/' };

get '/rocksdb/' => sub {
  use Data::Dumper;
  template 'directory' => {
    title => 'Snapshots',
    snapshots => [
      map { {name => $_->id , uri => "/rocksdb/snapshots/" . $_->id } }
          EPFL::Zeebe::RocksDB::Snapshot->all
    ]
  };
};

get '/rocksdb/snapshots/:snapshotid[StrMatch[qr{\d+-\d+-\d+}]]' => sub {
    my $id = route_parameters->get('snapshotid');
    my $rocksdb = EPFL::Zeebe::RocksDB::Snapshot->load($id)
      or return a_404;
    template "rocksdb-mainmenu", {
      moniker => "Snapshot $id",
      rocksdb => $rocksdb,
    };
};

get '/perlinfo' => sub {
  return "<pre>$EPFL::Zeebe::Observability::Snapshot::datadir</pre>";
};
