use strict;
use warnings;

use EPFL::Zeebe::Observability;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;
use Ref::Util qw<is_coderef>;

my $app = EPFL::Zeebe::Observability->to_app;
ok( is_coderef($app), 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );

ok( $res->is_success, '[GET /] successful' );
