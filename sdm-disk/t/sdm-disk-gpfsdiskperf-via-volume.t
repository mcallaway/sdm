
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

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Don't assume we can reach SNMP on named hosts for non GI networks";
}

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-lib.pm";
ok( SDM::Test::Lib->testinit == 0, "init db");
ok( SDM::Test::Lib->testdata == 0, "data db");

my $res;
my @res;

#my $vol = SDM::Disk::Volume->get( id => 1 );
#@res = $vol->gpfs_disk_perf;
#my @items = map { $_->gpfsDiskPerfFSName } @res;
#print join("\n",@items);

my @g = SDM::Disk::GpfsDiskPerf->get( filername => 'gpfs-dev', mount_path => '/gscmnt/gpfsdev12' );
print "res: " . Data::Dumper::Dumper @g;
#my @items = map { $_->gpfsDiskPerfFSName } @g;
#print join("\n",@items);

done_testing();
