
use strict;
use warnings;

use System;

use Test::More;
use Test::Output;
use Test::Exception;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

my $res;
my $params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";
my $perl = "$^X -I " . join(" -I ",@INC);
system("$perl $top/t/00-system-disk-prep-test-database.t");
ok($? >> 8 == 0, "prep test db ok");

# Test insufficient creation params
my @params = ();
ok( ! defined System::Disk::Filer->create( @params ), "properly fail to create filer with empty param" );

# Test creation
@params = ( name => 'nfs11' );
$res = System::Disk::Filer->create( @params );
ok( $res->id eq 'nfs11', "properly created new filer");
@params = ( name => 'nfs11' );
$res = System::Disk::Filer->get( @params );
ok( $res->id eq 'nfs11', "properly got new filer");

@params = ( name => 'nfs12' );
$res = System::Disk::Filer->create( @params );
ok( $res->id eq 'nfs12', "properly created another new filer");

# Test deletion of 1 Filer
@params = ( name => 'nfs11' );
$res = System::Disk::Filer->get( @params );
$res->delete();
isa_ok( $res, 'UR::DeletedRef', "properly delete filer" );

# Test update of value
@params = ( name => 'nfs12' );
$res = System::Disk::Filer->get( @params );
$res->status(1);
ok( $res->status == 1, "status set to 1");

# Update last modified to age the filer
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time()) );
ok( $res->is_current(86400) == 0, "filer is current" );
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() - 87000 ) );
ok( $res->is_current(86400) == 1, "filer is aged");

# Now test 'delete'
$res = System::Disk::Filer->get();
$res->delete();
isa_ok( $res, 'UR::DeletedRef' );

done_testing();
