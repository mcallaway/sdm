
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
use_ok( 'SDM::View::Diskstatus::Html' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

ok( SDM::Test::Lib->testinit == 0, "ok: init db");

my $o = SDM::View::Diskstatus::Html->create();
my $page = $o->_generate_content();

my $tree = HTML::TreeBuilder->new_from_content($page) or die "$!";
my $title = $tree->look_down( '_tag', 'title' );
ok($title->as_text eq "Disk Usage Information", "ok: title");

my $ftable = $tree->look_down( _tag => 'div', id => 'filer_table' );
my @rows = $ftable->look_down( _tag => 'tr' );
ok($rows[0]->content->[0]->as_text eq "Filer", "ok: filer_table");

my $gtable = $tree->look_down( _tag => 'div', id => 'group_table' );
@rows = $gtable->look_down( _tag => 'tr' );
ok($rows[0]->content->[0]->as_text eq "Disk Group Name", "ok: group_table");

my $vtable = $tree->look_down( _tag => 'div', id => 'volume_table' );
@rows = $vtable->look_down( _tag => 'tr' );
ok($rows[0]->content->[0]->as_text eq "Mount Path", "ok: volume_table");

done_testing();
