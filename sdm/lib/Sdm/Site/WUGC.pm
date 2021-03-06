
package Sdm::Site::WUGC;
use strict;
use warnings;

# ensure nothing loads the old Sdm::Config module
BEGIN { $INC{"Sdm/Config.pm"} = 'no' };

# Default production DB settings
$ENV{SDM_DEPLOYMENT} ||= 'production';
$ENV{SDM_GENOME_INSTITUTE_NETWORKS} = 1;
$ENV{SDM_ZENOSS_DATABASE_HOSTNAME} ||= 'monitor.gsc.wustl.edu';

if ($ENV{SDM_DEPLOYMENT} eq 'testing') {
    $ENV{SDM_DATABASE_DRIVER} ||= 'SQLite';
    $ENV{SDM_DATABASE_HOSTNAME} ||= 'localhost';
} elsif ($ENV{SDM_DEPLOYMENT} eq 'production') {
    $ENV{SDM_DATABASE_DRIVER} ||= 'Pg';
    #$ENV{SDM_DATABASE_HOSTNAME} ||= 'sysmgr.gsc.wustl.edu';
    $ENV{SDM_DATABASE_HOSTNAME} ||= 'localhost';
}

1;

=pod

=head1 NAME

Sdm::Site::WUGC - internal configuration for the WU Genome Institute.

=head1 DESCRIPTION

Configures the sdm suite to work on the internal network at
The Genome Institute at Washington University

=head1 BUGS

For defects with any software in the genome namespace,
contact sdm-dev@genome.wustl.edu.

=cut



