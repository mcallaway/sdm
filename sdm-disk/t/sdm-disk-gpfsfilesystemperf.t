
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
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Test::Lib->testinit == 0, "init db");
ok( SDM::Test::Lib->testdata == 0, "data db");

my $res;
my @res;

@res = SDM::Disk::GpfsFileSystemPerf->get( filername => 'fakefiler' );
ok( ! @res, "fake filer returns undef" );

@res = SDM::Disk::GpfsFileSystemPerf->get( filername => 'gpfs-dev' );
$res = shift @res;

ok( ref $res eq "SDM::Disk::GpfsFileSystemPerf", "object made correctly");
ok( ref $res->filer eq 'SDM::Disk::Filer', "filer object related");

ok( defined $res->filername, "attr set" );
ok( defined $res->filer, "attr set" );
#ok( defined $res->volume, "attr set" );
ok( defined $res->mount_path, "attr set" );
ok( defined $res->gpfsFileSystemPerfName, "attr set" );
ok( defined $res->gpfsFileSystemBytesReadL, "attr set" );
ok( defined $res->gpfsFileSystemBytesReadH, "attr set" );
ok( defined $res->gpfsFileSystemBytesCacheL, "attr set" );
ok( defined $res->gpfsFileSystemBytesCacheH, "attr set" );
ok( defined $res->gpfsFileSystemBytesWrittenL, "attr set" );
ok( defined $res->gpfsFileSystemBytesWrittenH, "attr set" );
ok( defined $res->gpfsFileSystemReads, "attr set" );
ok( defined $res->gpfsFileSystemCaches, "attr set" );
ok( defined $res->gpfsFileSystemWrites, "attr set" );
ok( defined $res->gpfsFileSystemOpenCalls, "attr set" );
ok( defined $res->gpfsFileSystemCloseCalls, "attr set" );
ok( defined $res->gpfsFileSystemReadCalls, "attr set" );
ok( defined $res->gpfsFileSystemWriteCalls, "attr set" );
ok( defined $res->gpfsFileSystemReaddirCalls, "attr set" );
ok( defined $res->gpfsFileSystemInodesWritten, "attr set" );
ok( defined $res->gpfsFileSystemInodesRead, "attr set" );
ok( defined $res->gpfsFileSystemInodesDeleted, "attr set" );
ok( defined $res->gpfsFileSystemInodesCreated, "attr set" );
ok( defined $res->gpfsFileSystemStatCacheHit, "attr set" );
ok( defined $res->gpfsFileSystemStatCacheMiss, "attr set" );

done_testing();
