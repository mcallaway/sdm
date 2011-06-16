
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
my @params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Test::Lib->testinit == 0, "ok: init db");

@params = ( name => 'nsams2k1' );
my $array = SDM::Disk::Array->create( @params );
@params = ( arrayname => 'nsams2k1', disk_type => 'sata', disk_num => 192, disk_size => 1833 * 1024 * 1024 );
my $b1 = SDM::Disk::ArrayDiskSet->create( @params );
@params = ( arrayname => 'nsams2k1', disk_type => 'sas', disk_num => 228, disk_size => 536 * 1024 * 1024 );
my $b2 = SDM::Disk::ArrayDiskSet->create( @params );

UR::Context->commit();

ok( defined $b1, "set defined");
ok( defined $b2, "set defined");
ok( defined $array, "array defined");

my $s = $array->arraysize;
ok( $s->id == 497176018944, "size ok");
ok( ref $s eq 'SDM::Value::KBytes' );
my $v = $s->create_view( perspective => 'default', toolkit => 'text' );
ok( $v->content eq '497,176,018,944 (497 TB)', "formatted value ok");

@params = ( name => 'nsams2k1' );
$array = SDM::Disk::Array->get( @params );
my @got = $array->disk_type();
my @expected = ("sata","sas");
ok( is_deeply( \@got, \@expected, "is_deeply"), "disk_type matches");

done_testing();
