#! /usr/bin/perl

use Test::More;
use Test::Output;
use FindBin;
use IPC::Cmd;
use File::Basename qw/dirname/;

my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";

# Preserve the -I args we used to run this script.
my $perl = "$^X -I " . join(" -I ",@INC);
my $system = IPC::Cmd::can_run("system");
unless ($system) {
    if (-e "./system-disk/system/bin/system") {
        $system = "./system-disk/system/bin/system";
    } elsif (-e "./system/bin/system") {
        $system = "./system/bin/system";
    } elsif (-e "../system/bin/system") {
        $system = "../system/bin/system";
    } else {
        die "Can't find 'system' executable";
    }
}

use_ok( 'System' ) or die "Run with -I to include system/lib";
use_ok( 'System::Disk' ) or die "Run with -I to include system-disk/lib";

# Use same perl invocation to run this
system("$perl $top/t/00-system-disk-prep-test-database.t");
ok( $? >> 8 == 0, "ok: $command") or die "Cannot remake test DB";

# -- Now we're prepped, run some commands

sub runcmd {
    my $command = shift;
    $ENV{SYSTEM_NO_REQUIRE_USER_VERIFY}=1;
    print "$system $command\n";
    system("$perl $system $command");
    ok( $? >> 8 == 0, "ok: $command") or die;
    UR::Context->commit() or die;
}

# More complicated tests of foreign key constraints and order of ops.
# array host filer group volume
runcmd("disk group add --name SYSTEMS");
runcmd("disk filer add --name gpfs");
runcmd("disk host add --hostname linuscs103");
runcmd("disk array add --name nsams2k1");
runcmd("disk volume add --mount-path=/gscmnt/ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs --disk-group=SYSTEMS");

# Assign and detach: arrays and hosts
runcmd("disk array assign nsams2k1 linuscs103");
runcmd("disk host assign linuscs103 gpfs");

# Delete a volume that has mappings to filers and arrays
runcmd("disk volume delete 1");

done_testing();
