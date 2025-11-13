#!/usr/bin/env perl

=head1 NAME

C<normalize-accepting.pl> - Refresh the C<EVENT_SCOPE> column family to the best of our knowledge


=head1 USAGE

  normalize-accepting.pl <snapshotdir>

=head1 DESCRIPTION

Ensure that any JOB record has a corresponding EVENT_SCOPE record
(pointed to by its C<.jobRecord.elementInstanceKey>) with values

=over

=item C<activated=1>

otherwise that job will discard variables in the CompleteJob RPC; see
https://go.epfl.ch/INC0468981 et al

=item C<interrupting=[]>

mostly because we have no idea what this field does.

=back

=cut

use FindBin qw($Bin $Script);
use File::Spec;
# For ZeebeDB::* libs while outside the container - Doesn't harm inside it:
use lib "$Bin/../docker/zeebe-tools/perllib";

# If we can't have RocksDB, run the same script inside Docker:
BEGIN {
  eval {
    require RocksDB;
  } or do {
    my $docker_build_dir = "$Bin/../docker/zeebe-tools";
    system("docker", "build", "-t", "epfl-si/zeebe-tools",
           $docker_build_dir)
      and die "Unable to build Docker image in $docker_build_dir (exit code $?)";
    my $rocksdb_dir = File::Spec->rel2abs(pop @ARGV);
    exec("docker", "run", "--rm",
         "-v", "$Bin/$Script:/$Script:ro",
         "-v", "$Bin/perllib:/usr/local/lib/site_perl:ro",
         "-v", "$rocksdb_dir:/rocksdb",
         "epfl-si/zeebe-tools",
         "perl", "/$Script", @ARGV, "/rocksdb");
  };
}

use v5.21;
use Data::MessagePack;
use ZeebeDB;
use ZeebeDB::Key;
use List::Util qw(max);

my $db = ZeebeDB->open($ARGV[0]);

my @processDefinitions;

my %elementInstanceKeys;
warn "Scanning PROCESS_CACHE...\n";
$db->walk_column_family_raw(PROCESS_CACHE => sub {
  my ($rawKey, $bpmnSchema, $columnFamily, $processDefinitionKey) = @_;
  push @processDefinitions, {
    key => $processDefinitionKey,
    value => $bpmnSchema
   };
  $db->delete($rawKey);
});

warn "... Found " . scalar(@processDefinitions) . " process definitions.\n";

my $cf = ZeebeDB::Key::Tok::ColumnFamily->new("PROCESS_CACHE");
my $subs = 0;
foreach my $pdef (@processDefinitions) {
  $subs += $pdef->{value} =~ s<zeebe:taskDefinition type="phdAssessFillForm" retries="0">
                              <zeebe:taskDefinition type="phdAssessFillForm" retries="9">g;
  $subs += $pdef->{value} =~ s<zeebe:taskDefinition type="([^"]*)" retries="0">
                              <zeebe:taskDefinition type="${  1 }"            >g;
  $db->put(ZeebeDB::Key->serialize($cf, $pdef->{key}), $pdef->{value}) ;
}

$db->close();

warn "Rewrote $subs `retries` in `zeebe:taskDefinition` XML elements\n";
