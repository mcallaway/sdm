
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
if ($top =~ /deploy/) {
    require "$top/t/sdm-disk-lib.pm";
} else {
    require "$top/../sdm-disk/t/sdm-disk-lib.pm";
}
ok( SDM::Test::Lib->has_gpfs_snmp == 1, "gpfs ok");
ok( SDM::Test::Lib->testinit == 0, "init db");
ok( SDM::Test::Lib->testdata == 0, "data db");

my $res;
my @res;

@res = SDM::Disk::Host->get( hostname => 'linuscs107' );
$res = shift @res;
$res = $res->gpfs_node_status;

ok( ref $res eq "SDM::Gpfs::GpfsNodeStatus", "object made correctly");
ok( ref $res->filer eq 'SDM::Disk::Filer', "filer object related");

ok( defined $res->filername, "attr set" );
ok( defined $res->filer, "attr set" );
ok( defined $res->gpfsNodeName, "attr set" );
ok( defined $res->gpfsNodeIP, "attr set" );
ok( defined $res->gpfsNodePlatform, "attr set" );
ok( defined $res->gpfsNodeStatus, "attr set" );
ok( defined $res->gpfsNodeFailureCount, "attr set" );
ok( defined $res->gpfsNodeThreadWait, "attr set" );
ok( defined $res->gpfsNodeHealthy, "attr set" );
ok( defined $res->gpfsNodeDiagnosis, "attr set" );
ok( defined $res->gpfsNodeVersion, "attr set" );

done_testing();
