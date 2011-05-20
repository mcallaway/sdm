
package SDM::Disk::GpfsNodeStatus;

use strict;
use warnings;

use SDM;

class SDM::Disk::GpfsNodeStatus {
    id_by => [
        id => { is => 'Number' }
    ],
    has => [
        filername               => { is => 'Text' },
        filer                   => { is => 'SDM::Disk::Filer', id_by => 'filername' },
        gpfsNodeName            => { is => 'Text' },
        gpfsNodeIP              => { is => 'Text' },
        gpfsNodePlatform        => { is => 'Text' },
        gpfsNodeStatus          => { is => 'Text' },
        gpfsNodeFailureCount    => { is => 'Number' },
        gpfsNodeThreadWait      => { is => 'Number' },
        gpfsNodeHealthy         => { is => 'Text' },
        gpfsNodeDiagnosis       => { is => 'Text' },
        gpfsNodeVersion         => { is => 'Text' },
    ],
    has_constant => [
        snmp_table  => { value => 'gpfsNodeStatusTable' }
    ],
    data_source => UR::DataSource::Default->create(),
};

sub __load__ {
    my ($class, $bx, $headers) = @_;
    my (%params) = $bx->_params_list;
    my $filername = $params{filername};
    my $snmp_table = $bx->subject_class_name->__meta__->property_meta_for_name('snmp_table')->default_value;

    # Make a header row from class properties.
    my @properties = $class->__meta__->properties;
    my @header = map { $_->property_name } sort @properties;
    push @header, 'id';

    # Return an empty list if error.
    my @rows = [];
    my $filer = SDM::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $class->error_message(__PACKAGE__ . " no filer named $filername found");
        return \@header, sub { shift @rows };
    }

    # Query master node of cluster for SNMP table.
    my $master;
    foreach my $host ( $filer->host ) {
        $master = $host->hostname if ($host->master);
    }
    my $snmp = SDM::Utility::SNMP->create( hostname => $master, loglevel => 'DEBUG' );
    my $table = $snmp->read_snmp_into_table( $snmp_table );

    my $id;
    while (my ($key,$result) = each %$table ) {
        $result->{id} = $id++;
        $result->{filername} = $filername;
        # Ensure values are in the same order as the header row.
        my @row = map { $result->{$_} } @header;
        push @rows, [@row];
    }
    return \@header, \@rows;
}

1;
