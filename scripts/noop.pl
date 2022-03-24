=head1 NAME

noop.pl - For testing the checksum regeneration logic.

=head1 DESCRIPTION

Open and close a Zeebe RocksDB database, but do not write anything
into it; just update the C<12345-12-1234567-123456.checksum> file,
which should therefore not significantly change. (i.e. same
uncommented lines, same C<< combinedValue = >> pragma)

=cut

use warnings qw(all);
use strict;

use FindBin qw($Bin $Script);
use lib "$FindBin::Bin/../docker/zeebe-observability/lib";
use ZeebeDB;

use v5.21;

ZeebeDB->open($ARGV[0])->close;
