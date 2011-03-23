
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

my $res;
my $params;

# Start with a fresh database
system('bash ./t/00-disk-prep-test-database.sh');
ok($? >> 8 == 0, "prep test db ok");

# Test insufficient creation params
my @params = ();
ok( ! defined System::Disk::Export->create( @params ), "properly fail to create export with empty param" );

# A export is a mapping between an Export and a Volume

# Test creation
@params = ( filername => 'filer', physical_path => '/vol/sata800' );
my $export = System::Disk::Export->create( @params );
ok( defined $export->id, "properly created new export");

@params = ();
$res = System::Disk::Export->get( @params );
ok( defined $res->id, "properly got new export");

@params = ( filername => 'filer', physical_path => '/vol/sata801' );
$export = System::Disk::Export->create( @params );
ok( defined $export->id, "properly made new export");

# Now test 'delete'
foreach $res ( System::Disk::Export->get() ) {
    $res->delete();
    isa_ok( $res, 'UR::DeletedRef' );
}

done_testing();
