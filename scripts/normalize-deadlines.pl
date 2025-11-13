#!/usr/bin/env perl

=head1 NAME

C<normalize-deadlines.pl> - Refresh the C<JOB_DEADLINES> column family from the ground truth in C<JOBS>

=head1 USAGE

  normalize-deadlines.pl <snapshotdir>

💡 If the C<RocksDB> Perl module (whose build is a bit of an
adventure) is unavailable, the script automatically re-runs itself
through the Docker image built from C<../docker/zeebe-tools>.

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

my $db = ZeebeDB->open($ARGV[0]);

my %job_deadlines;

warn "Scanning JOB_STATES...\n";
$db->walk_column_family(JOB_STATES => sub {
  my (undef, $state, undef, $jobKey) = @_;
  $jobKey = $jobKey->pretty;
  if ($state->{jobState} =~ m/ACTIVATED|ACTIVATABLE/) {
    $job_deadlines{$jobKey} = 1;
  }
});
warn ("... " . keys(%job_deadlines) . " activated jobs found.\n");

warn "Scanning JOBS...\n";
$db->walk_column_family(JOBS => sub {
  my (undef, $job, $cf, $jobKey) = @_;
  $jobKey = $jobKey->pretty;
  next unless $job_deadlines{$jobKey} and (my $deadline = $job->{jobRecord}->{deadline});
  $job_deadlines{$jobKey} = {
    timestamp => $deadline,
    key => [
      ZeebeDB::Key::Tok::Timestamp->new($deadline),
      ZeebeDB::Key::Tok::ZeebeKey->new($jobKey)
    ]
  };
});

my $orphan_count = 0;
foreach my $j (keys %job_deadlines) {
  if ($job_deadlines{$j} == 1) {
    $orphan_count++;
    delete $job_deadlines{$j};
  }
}
warn ("... found $orphan_count jobs without a deadline.\n");

warn "Deleting all JOB_DEADLINES...\n";
my $deleted_count = 0;
$db->walk_column_family(JOB_DEADLINES => sub {
  my ($key) = @_;
  $db->delete($key);
  $deleted_count++;
});
warn "... $deleted_count entries deleted.\n";

warn "Populating JOB_DEADLINES...\n";
my $deadline_cf = ZeebeDB::Key::Tok::ColumnFamily->new("JOB_DEADLINES");
my $nil = Data::MessagePack->pack(-1);
foreach my $deadline (sort { $a->{timestamp} <=> $b->{timestamp}} (values %job_deadlines)) {
  $db->put(ZeebeDB::Key->serialize($deadline_cf, @{$deadline->{key}}), $nil)
}
warn "... " . values(%job_deadlines) . " entries added.\n";

$db->close();
