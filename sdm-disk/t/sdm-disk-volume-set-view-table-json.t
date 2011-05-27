
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Test::Output;
use Test::Exception;
use Data::Dumper;

use HTML::TreeBuilder;

use_ok( 'SDM' );
use_ok( 'SDM::Disk::Volume::Set::View::Table::Json' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-lib.pm";

my $t = SDM::Test::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

# This is what Rest.psgi does
my @s = SDM::Disk::Volume->define_set()->members();
my $s = $s[0];

# No view class found for UR::Value::Text if perspective is 'table'
#my $v = $s->create_view( perspective => 'table', toolkit => 'json' );

# Deep recursion generating view of aspect UR::Value::Text if perspective is 'default'
# Deep recursion on subroutine "UR::Object::View::Default::Json::_jsobj" 
my $v = $s->create_view( perspective => 'default', toolkit => 'json' );

my $json = $v->_generate_content();

print Data::Dumper::Dumper $json;
__END__

# This must match the data used in SDM::Test::Lib->testdata
my $expected = {
  'iTotalDisplayRecords' => 1,
  'iTotalRecords' => 1,
  'aaData' => [
                [
                  '/gscmnt/gc2111',
                  100,
                  50,
                  '50',
                  'SYSTEMS_DEVELOPMENT',
                  'gpfs-dev',
                  '0000-00-00 00:00:00'
                ]
              ],
  'sEcho' => 1
};

ok( is_deeply( $json, $expected, "ok: is_deeply" ), "ok: json match");

done_testing();
