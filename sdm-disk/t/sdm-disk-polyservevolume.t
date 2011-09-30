
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use SDM;

use Test::More;
use Test::Output;
use Test::Exception;

my $res;
my $params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Test::Lib->testinit == 0, "ok: init db");

# Test insufficient creation params
my @params = ();
ok( ! defined SDM::Disk::PolyserveVolume->create( @params ), "properly fail to create volume with empty param" );
@params = ( mount_point => '/gscmnt', name => 'sata800' );
ok( ! defined SDM::Disk::PolyserveVolume->create( @params ), "properly fail to create volume with no filer or physical path" );
@params = ( physical_path => '/vol/sata800' );
ok( ! defined SDM::Disk::PolyserveVolume->create( @params ), "properly fail to create volume with no filer or mount_point" );
@params = ( mount_point => '/gscmnt', physical_path => '/vol/sata800' );
ok( ! defined SDM::Disk::PolyserveVolume->create( @params ), "properly fail to create volume with no name" );
@params = ( mount_point => '/gscmnt', name => 'sata800', filername => 'nfs11' );
ok( ! defined SDM::Disk::PolyserveVolume->create( @params ), "properly fail to create volume with no physical_path" );
@params = ( physical_path => '/vol/sata800', filername => 'nfs11' );
ok( ! defined SDM::Disk::PolyserveVolume->create( @params ), "properly fail to create volume with no mount_point or name" );
@params = ( filername => 'nfs11' );
ok( ! defined SDM::Disk::PolyserveVolume->create( @params ), "properly fail to create volume with no physical mount_point and name" );

# Create filer to test with
my $nfs11 = SDM::Disk::Filer->create( name => 'nfs11', type => 'polyserve' );
ok( defined $nfs11, "created test filer ok");
ok( my $array = SDM::Disk::Array->create( name => 'nsams2k1' ), "created test array ok");
ok( my $host = SDM::Disk::Host->create( hostname => 'linuscs103' ), "created test host ok");
my $r = $array->assign( "linuscs103" );
isa_ok( $r, "SDM::Disk::HostArrayBridge" );
$r = $host->assign( "nfs11" );
isa_ok( $r, "SDM::Disk::FilerHostBridge" );
ok( defined SDM::Disk::Group->create( name => 'INFO_GENOME_MODELS' ), "created test group ok");

# Test creation
@params = ( filername => 'nfs11', mount_point => '/gscmnt', name => 'sata800', physical_path => '/vol/sata800', disk_group => 'INFO_GENOME_MODELS', total_kb => 2, used_kb => 1 );
$res = SDM::Disk::PolyserveVolume->create( @params );
ok( defined $res->id, "properly created new volume");
$res = SDM::Disk::PolyserveVolume->create( @params );
ok( ! defined $res, "properly refused to create duplicate volume");

done_testing();

