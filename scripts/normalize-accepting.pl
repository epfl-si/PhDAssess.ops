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

my %elementInstanceKeys;
warn "Scanning JOBS...\n";
my $jobCount = 0;
$db->walk_column_family(JOBS => sub {
  my (undef, $job, undef, $jobKey) = @_;

  my $elementInstanceKey = $job->{jobRecord}->{elementInstanceKey};
  warn "Duplicate elementInstanceKey: $elementInstanceKey" if $elementInstanceKeys{$elementInstanceKey}++;
  $jobCount++
});
warn sprintf("... %d distinct element instance keys found from %d jobs\n",
             scalar(keys(%elementInstanceKeys)), $jobCount);

warn "Scanning existing EVENT_SCOPE entries...\n";
my $eventScopeCount = 0;
my %eventScopeRaws;
$db->walk_column_family_raw(EVENT_SCOPE => sub {
  my (undef, $eventScopeRaw, undef, $eventScopeKey) = @_;
  $eventScopeRaws{$eventScopeRaw}++;
  my $eventScope = Data::MessagePack->unpack($eventScopeRaw);
  $eventScopeKey = $eventScopeKey->pretty;
  if (! $elementInstanceKeys{$eventScopeKey}) {
    warn "Event scope key $eventScopeKey doesn't belong to a job.";
  }
  delete $elementInstanceKeys{$eventScopeKey};
  $eventScopeCount++;
});
warn sprintf("... %d entries found, %d missing (will be recreated)\n",
             $eventScopeCount, scalar(keys(%elementInstanceKeys)));


%eventScopeRaws = reverse %eventScopeRaws;
my $mostFrequentEventScopeRaw = $eventScopeRaws{max(keys %eventScopeRaws)};
my $event_scope_cf = ZeebeDB::Key::Tok::ColumnFamily->new("EVENT_SCOPE");
foreach my $k (keys %elementInstanceKeys) {
  $db->put(ZeebeDB::Key->serialize($event_scope_cf, ZeebeDB::Key::Tok::ZeebeKey->new($k)),
           $mostFrequentEventScopeRaw);
}

$db->close();

=head1 JUSTIFICATION

From a dump of a snapshot (see L<read-snapshot.pl>), we made the following observations:

=over

=item *

“Element instances” (or whatever it is that lives in column family C<ELEMENT_INSTANCE_KEY>) appear to be a supertype of all the instances of BPMN things such as service tasks, exclusive gateways, processes and more (as per their C<.elementRecord.processInstanceRecord.bpmnElementType>).

=item *

(At least in our very simple BPMN schemas,) element instances that have a C<bpmnElementType> of C<SERVICE_TASK> are in bijection with C<JOBS>: that is, the C<.jobRecord.elementInstanceKey> of all C<JOBS> is unique and points to an C<ELEMENT_INSTANCE_KEY>, and conversely, all C<ELEMENT_INSTANCE_KEY> inhabitants with C<.elementRecord.processInstanceRecord.bpmnElementType == "SERVICE_TASK"> are bound to a C<JOB> in this way.

=item *

In the Java source code, namely L<DbEventScopeInstanceState.java|https://github.com/camunda/zeebe/blob/main/engine/src/main/java/io/camunda/zeebe/engine/state/instance/DbEventScopeInstanceState.java>, we can see that the C<accepting> flag is the condition for C<createTrigger> to be called in C<triggerEvent>. This flag is being read from the C<EVENT_SCOPE> column family (methods C<isAcceptingEvent>).

=item *

Ostensibly, the C<accepting> flag is set to true when the scope is being created (as part of L<ProcessInstanceElementActivatingApplier.applyState|https://github.com/camunda/zeebe/blob/main/engine/src/main/java/io/camunda/zeebe/engine/state/appliers/ProcessInstanceElementActivatingApplier.java#L249>) and can only ever be changed from true to false (see: calls to C<setAccepting()> in DbEventScopeInstanceState.java, op. cit.). There doesn't appear to be a case whence it is valid for that record to not exist at all, which still occurs in practice - Hence, this script.

=back

=cut
