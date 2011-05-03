
use strict;
use warnings;

BEGIN {
    $ENV{SYSTEM_DEPLOYMENT} = "testing";
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use System;

use Test::More;
use Test::Output;
use Test::Exception;

my $res;
my $params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/system-lib.pm";
ok( System::Test::Lib->testinit == 0, "ok: init db");

# Test insufficient creation params
my @params = ();
ok( ! defined System::Disk::Host->create( @params ), "properly fail to create host with empty param" );

# Test creation
@params = ( hostname => 'linuscs103' );
$res = System::Disk::Host->create( @params );
ok( $res->id eq 'linuscs103', "properly created new host");
@params = ( hostname => 'linuscs103' );
$res = System::Disk::Host->get( @params );
ok( $res->id eq 'linuscs103', "properly got new host");

@params = ( hostname => 'linuscs104' );
$res = System::Disk::Host->create( @params );
ok( $res->id eq 'linuscs104', "properly created another new host");

# Test deletion of 1 Host
@params = ( hostname => 'linuscs103' );
$res = System::Disk::Host->get( @params );
$res->delete();
isa_ok( $res, 'UR::DeletedRef', "properly delete host" );

# Test update of value
@params = ( hostname => 'linuscs104' );
$res = System::Disk::Host->get( @params );
$res->location("datacenter");
ok( $res->location eq "datacenter", "Location set to datacenter");

# Update created and last modified
$res->created( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time()) );
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() - 87000 ) );

# Test assign
my $filer = System::Disk::Filer->create( name => "gpfs" );
my $fhb = $res->assign( $filer->name );
isa_ok( $fhb, 'System::Disk::FilerHostBridge' );

# Now test 'delete'
$res = System::Disk::Host->get();
$res->delete();
isa_ok( $res, 'UR::DeletedRef' );

done_testing();
