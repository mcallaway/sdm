
package Sdm::Gpfs::GpfsClusterConfig;

use strict;
use warnings;

use Sdm;

class Sdm::Gpfs::GpfsClusterConfig {
    id_by => [
        # FIXME: id_by should be gpfsClusterName, but UR breaks with an id_by that isn't "id"
        id => { is => 'Number' },
    ],
    has => [
        filername                           => { is => 'Text' },
        gpfsClusterConfigName               => { is => 'Text' },
        gpfsClusterUidDomain                => { is => 'Text' },
        gpfsClusterRemoteShellCommand       => { is => 'Text' },
        gpfsClusterRemoteFileCopyCommand    => { is => 'Text' },
        gpfsClusterPrimaryServer            => { is => 'Text' },
        gpfsClusterSecondaryServer          => { is => 'Text' },
        gpfsClusterMaxBlockSize             => { is => 'Number' },
        gpfsClusterDistributedTokenServer   => { is => 'Number' },
        gpfsClusterFailureDetectionTime     => { is => 'Number' },
        gpfsClusterTCPPort                  => { is => 'Number' },
        gpfsClusterMinMissedPingTimeout     => { is => 'Number' },
        gpfsClusterMaxMissedPingTimeout     => { is => 'Number' },
    ],
    has_optional => [
        filer                               => { is => 'Sdm::Disk::Filer', id_by => 'filername' }
    ],
    has_constant => [
        snmp_table                          => { is => 'Text', value => 'gpfsClusterConfigTable' }
    ],
    data_source => UR::DataSource::Default->create(),
};

sub __load__ {
    my ($class, $bx, $headers) = @_;

    # Make a header row from class properties.
    my @properties = $class->__meta__->properties;
    my @header = map { $_->property_name } sort @properties;
    push @header, 'id';
    # Return an empty list if error.
    my @rows = [];

    my (%params) = $bx->_params_list;
    my $filername = $params{filername};
    unless ($filername) {
        $class->warning_message(__PACKAGE__ . " no filername given to query SNMP");
        return \@header, sub { shift @rows };
    }
    my $snmp_table = $bx->subject_class_name->__meta__->property_meta_for_name('snmp_table')->default_value;

    my $filer = Sdm::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $class->error_message(__PACKAGE__ . " no filer named $filername found");
        return \@header, sub { shift @rows };
    }

    # Query master node of cluster for SNMP table.
    my $master;
    foreach my $host ( $filer->host ) {
        $master = $host->hostname if ($host->master);
    }
    my $snmp = Sdm::Utility::SNMP->create( hostname => $master );
    unless ($snmp) {
        $class->error_message(__PACKAGE__ . " $master snmpd does not respond");
        return;
    }
    my $table = $snmp->read_snmp_into_table( $snmp_table );

    my $id;
    while (my ($key,$result) = each %$table) {
        $result->{id} = $id++;
        $result->{filername} = $filername;
        # Ensure values are in the same order as the header row.
        my @row = map { $result->{$_} } @header;
        push @rows, [@row];
    }
    return \@header, \@rows;
}

1;
