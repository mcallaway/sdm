
package System::Env::SYSTEM_DISK_GPFS_PRESENT;

$ENV{SYSTEM_DISK_GPFS_PRESENT} ||= 0;

if ($ENV{SYSTEM_GENOME_INSTITUTE_NETWORKS}) {
    $ENV{SYSTEM_DISK_GPFS_PRESENT} = 1;
}

1;