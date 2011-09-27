
package SDM::Test::Lib;

use strict;
use warnings;

BEGIN {
    # testing means use sqlite db, we do want to commit.
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Cwd qw/abs_path/;
use File::Basename qw/dirname/;
use IPC::Cmd qw/can_run/;
use Data::Dumper;

use SDM;

my $ds = SDM::DataSource::Disk->get();
my $driver = $ds->driver;
my $top = dirname dirname abs_path(__FILE__);
my $base = "$top/lib/SDM";
my $perl = "$^X -I $top/lib -I $top/../sdm/lib";
my $sdm = can_run("./bin/sdm");
unless ($sdm) {
    if (-e "./sdm-disk/sdm/bin/sdm") {
        $sdm = "./sdm-disk/sdm/bin/sdm";
    } elsif (-e "./sdm/bin/sdm") {
        $sdm = "./sdm/bin/sdm";
    } elsif (-e "../sdm/bin/sdm") {
        $sdm = "../sdm/bin/sdm";
    } else {
        die "Can't find 'sdm' executable";
    }
}

die "sdm not found in PATH" unless (defined $sdm);

sub new {
    my $class = shift;
    my $self = {
        'perl' => $perl,
        'sdm' => $sdm,
    };
    bless $self,$class;
    return $self;
}

sub runcmd {
    my $self = shift;
    my $command = shift;
    $ENV{SDM_NO_REQUIRE_USER_VERIFY} ||= 1;
    print("$command\n");
    system("$command");
    if ($? == -1) {
         print "failed to execute: $!\n";
    } elsif ($? & 127) {
         printf "child died with signal %d, %s coredump\n",
             ($? & 127),  ($? & 128) ? 'with' : 'without';
    } else {
         printf "child exited with value %d\n", $? >> 8;
    }
    ok( $? >> 8 == 0, "ok: $command") or die;
}

sub testinit {
    my $self = shift;
    if ($driver eq "SQLite") {
        print "flush sqlite3 DB\n";
        unlink "$base/DataSource/Disk.sqlite3";
        unlink "$base/DataSource/Disk.sqlite3-dump";
        print "make new sqlite3 DB\n";
        $self->runcmd("/usr/bin/sqlite3 $base/DataSource/Disk.sqlite3 < $base/DataSource/Disk.sqlite3.schema");
        $self->runcmd("/usr/bin/sqlite3 $base/DataSource/Disk.sqlite3 .dump > $base/DataSource/Disk.sqlite3-dump");
    }

    if ($driver eq "Pg") {
        print "flush and remake psql DB\n";
        $self->runcmd("/usr/bin/psql -w -d system -U system < $base/DataSource/Disk.psql.schema >/dev/null");
    }

    if ($driver eq "Oracle") {
        print "Use Oracle DB\n";
        open FILE, "<$base/DataSource/Disk.oracle.schema";
        my $sql = do { local $/; <FILE> };
        close(FILE);
        my $login = $ds->login;
        my $auth = $ds->auth;
        open ORA, "| sqlplus -s $login/$auth\@gcdev" or die "Can't pipe to sqlplus: $!";
        print ORA $sql;
        print ORA "exit";
        close(ORA);
    }

    print "flush and remake Meta\n";
    my $ds = "$top/../sdm/lib/SDM/DataSource";
    unlink "$ds/Meta.sqlite3";
    unlink "$ds/Meta.sqlite3-dump";
    $self->runcmd("/usr/bin/sqlite3 $ds/Meta.sqlite3 < $ds/Meta.sqlite3-schema");
    $self->runcmd("/usr/bin/sqlite3 $ds/Meta.sqlite3 .dump > $ds/Meta.sqlite3-dump");
    return 0;
}

sub testdata {
    my $self = shift;
    my $filer = SDM::Disk::Filer->create(name => "gpfs", status => 1, comments => "This is a comment");
    $filer->created("0000-00-00 00:00:00");
    $filer->last_modified("0000-00-00 00:00:00");
    $filer = SDM::Disk::Filer->create(name => "gpfs2", status => 1, comments => "This is another comment");
    $filer->created("0000-00-00 00:00:00");
    $filer->last_modified("0000-00-00 00:00:00");
    $filer = SDM::Disk::Filer->create(name => "gpfs-dev", status => 1, comments => "This is another comment");
    $filer->created("0000-00-00 00:00:00");
    $filer->last_modified("0000-00-00 00:00:00");
    my $host = SDM::Disk::Host->create(hostname => "linuscs103", master => 0);
    $host->assign("gpfs");
    $host = SDM::Disk::Host->create(hostname => "linuscs107", master => 1);
    $host->assign("gpfs-dev");
    my $array = SDM::Disk::Array->create(name => "nsams2k1");
    $array->assign("linuscs103");
    $array = SDM::Disk::Array->create(name => "nsams2k2");
    $array->assign("linuscs107");

    SDM::Disk::Group->create(name => "SYSTEMS_DEVELOPMENT");
    SDM::Disk::Group->create(name => "SYSTEMS");
    SDM::Disk::Group->create(name => "INFO_APIPE");

    # If you change these sample volumes, unit tests expected values will also change.
    SDM::Disk::Volume->create( name=>"gc2111", mount_point => '/gscmnt', physical_path=>"/vol/gc2111", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>50, filername=>"gpfs-dev");
    SDM::Disk::Volume->create( name=>"gpfsdev2", mount_point => '/gscmnt', physical_path=>"/vol/gpfsdev2", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>50, filername=>"gpfs-dev");
    SDM::Disk::Volume->create( name=>"gc2112", mount_point => '/gscmnt', physical_path=>"/vol/gc2112", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>90, filername=>"gpfs");
    SDM::Disk::Volume->create( name=>"gc2113", mount_point => '/gscmnt', physical_path=>"/vol/gc2113", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>90, filername=>"gpfs2");
    SDM::Disk::Volume->create( name=>"gc2114", mount_point => '/gscmnt', physical_path=>"/vol/gc2114", disk_group=>"SYSTEMS", total_kb=>100, used_kb=>90, filername=>"gpfs2");
    SDM::Disk::Volume->create( name=>"gc2115", mount_point => '/gscmnt', physical_path=>"/vol/gc2115", disk_group=>"INFO_APIPE", total_kb=>100, used_kb=>90, filername=>"gpfs2");
    SDM::Disk::Volume->create( name=>"gc2116", mount_point => '/gscmnt', physical_path=>"/vol/gc2116", total_kb=>100, used_kb=>90, filername=>"gpfs-dev");
    UR::Context->commit();
    return 0;
}

sub has_gpfs_snmp {
    my $self = shift;
    my $master = "linuscs107";
    warn "snmpwalk: check $master for gpfsClusterConfigTable";
    open(PROG, "/usr/bin/snmpwalk -v 2c -c gscpublic -r2 -t5 $master gpfsClusterConfigTable 2>&1 |");
    my $output = <PROG>;
    close(PROG);
    if ($output =~ /No Such Object/i) {
        plan skip_all => "gpfs snmp subagent not running";
        return 0;
    }
    return 1;
}

1;

