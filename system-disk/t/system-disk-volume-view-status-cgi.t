
use strict;
use warnings;

BEGIN {
    $ENV{SYSTEM_DEPLOYMENT} = "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};


use System;

use Test::More;
use Test::Output;
use Test::Exception;

use URI;
use JSON;

use_ok( 'System' );
use_ok( 'System::Disk::Volume::View::Status::Cgi' );

my $q;
my $o;
my $r;
my @r;
my $uri;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/system-lib.pm";
ok( System::Test::Lib->testinit == 0, "ok: init db");

ok( defined System::Disk::Filer->create( name => 'gpfs' ), "ok: add gpfs" );
ok( defined System::Disk::Filer->create( name => 'gpfs2' ), "ok: add gpfs2" );
ok( defined System::Disk::Group->create( name => 'INFO_APIPE' ), "ok: add INFO_APIPE" );
ok( defined System::Disk::Group->create( name => 'INFO_GENOME_MODEL' ), "ok: add INFO_GENOME_MODEL" );
ok( defined System::Disk::Volume->create( filername => 'gpfs', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800', disk_group => 'INFO_APIPE', total_kb => 100, used_kb => 10 ), "ok: created sata800" );
ok( defined System::Disk::Volume->create( filername => 'gpfs2', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800'), "ok: added a sata800 mount" );
ok( defined System::Disk::Volume->create( filername => 'gpfs2', mount_path => '/gscmnt/sata801', physical_path => '/vol/sata801', disk_group => 'INFO_APIPE', total_kb => 150, used_kb => 20 ), "ok: created sata801" );
ok( defined System::Disk::Volume->create( filername => 'gpfs2', mount_path => '/gscmnt/sata802', physical_path => '/vol/sata802', disk_group => 'INFO_GENOME_MODEL', total_kb => 200, used_kb => 30 ), "ok: created sata802" );
UR::Context->commit();

# sSearch=
# iSortCol_0=
$uri = '/site/system/disk/volume/status.html.cgi?sEcho=11&iColumns=7&sColumns=&iDisplayStart=0&iDisplayLength=25&sSearch=&bEscapeRegex=true&sSearch_0=&bEscapeRegex_0=true&bSearchable_0=true&sSearch_1=&bEscapeRegex_1=true&bSearchable_1=true&sSearch_2=&bEscapeRegex_2=true&bSearchable_2=true&sSearch_3=&bEscapeRegex_3=true&bSearchable_3=true&sSearch_4=&bEscapeRegex_4=true&bSearchable_4=true&sSearch_5=&bEscapeRegex_5=true&bSearchable_5=true&iSortingCols=1&iSortCol_0=0&sSortDir_0=desc&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=true&bSortable_4=true&bSortable_5=true&rm=table_data HTTP/1.1';
$q = URI->new($uri);
$ENV{QUERY_URI} = $uri;
$o = System::Disk::Volume::View::Status::Cgi->new();
$r = $o->run();
my $json = JSON->new();
$r = $json->decode($r);
my $expected =  {
  'iTotalRecords' => 3,
  'iTotalDisplayRecords' => 3,
  'aaData' => [
                [
                  '/gscmnt/sata800',
                  '100 (100 KB)',
                  '10 (10 KB)',
                  '10 %',
                  'INFO_APIPE',
                  'gpfs,gpfs2',
                  'unknown'
                ],
                [
                  '/gscmnt/sata801',
                  '150 (150 KB)',
                  '20 (20 KB)',
                  '13 %',
                  'INFO_APIPE',
                  'gpfs2',
                  'unknown'
                ],
                [
                  '/gscmnt/sata802',
                  '200 (200 KB)',
                  '30 (30 KB)',
                  '15 %',
                  'INFO_GENOME_MODEL',
                  'gpfs2',
                  'unknown'
                ]
              ],
  'sEcho' => 1
};
ok( is_deeply( $r, $expected, "ok: is_deeply"), "ok: json match");

$uri = '/site/system/disk/volume/status.html.cgi?sEcho=11&iColumns=7&sColumns=&iDisplayStart=0&iDisplayLength=25&sSearch=&bEscapeRegex=true&sSearch_0=&bEscapeRegex_0=true&bSearchable_0=true&sSearch_1=&bEscapeRegex_1=true&bSearchable_1=true&sSearch_2=&bEscapeRegex_2=true&bSearchable_2=true&sSearch_3=&bEscapeRegex_3=true&bSearchable_3=true&sSearch_4=&bEscapeRegex_4=true&bSearchable_4=true&sSearch_5=&bEscapeRegex_5=true&bSearchable_5=true&iSortingCols=1&iSortCol_0=5&sSortDir_0=desc&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=true&bSortable_4=true&bSortable_5=true&rm=table_data HTTP/1.1';
$q = URI->new($uri);
$ENV{QUERY_URI} = $uri;
$o = System::Disk::Volume::View::Status::Cgi->new();
$r = $o->run();
my $json = JSON->new();
$r = $json->decode($r);
print Data::Dumper::Dumper $r;

done_testing();

