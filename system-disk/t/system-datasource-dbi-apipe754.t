
use strict;
use warnings;
use System;
use Test::More;
use Test::Output;
use Test::Exception;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/system-lib.pm";
ok( System::Test::Lib->testinit == 0, "ok: init db");

# Test creation
my @params = ( name => 'nsams2k1' );
my $res = System::Disk::Array->create( @params );
ok( $res->id eq 'nsams2k1', "properly created new array");
# Look for warning around line 830
stderr_unlike { UR::Context->commit; } qr|uninitialized value in subroutine entry at .*/UR/DBI.pm line 83\d|, "APIPE-754: issue in UR/DBI.pm";
done_testing();
