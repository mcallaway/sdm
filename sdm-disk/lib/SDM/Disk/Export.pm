
package SDM::Disk::Export;

use strict;
use warnings;

use SDM;

# This is strange and ugly use of class definition that I use to set
# id_sequence_generator_name for Oracle only.
my $classdef = {
    table_name => 'disk_export',
    id_by => [
        id              => { is => 'Number' },
    ],
    has => [
        filername       => { is => 'Text', len => 255 },
        physical_path   => { is => 'Text', len => 255 },
        filer           => { is => 'SDM::Disk::Filer', id_by => 'filername' },
    ],
    has_optional => [
        volume          => { is => 'SDM::Disk::Volume', id_by => 'id' },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
};

# Only oracle needs this
my $ds = SDM::DataSource::Disk->get();
my $driver = $ds->driver;
$classdef->{id_sequence_generator_name} = 'disk_export_id' if ($driver eq "Oracle");
class SDM::Disk::Export $classdef;

sub create {
    my $self = shift;
    my (%params) = @_ if scalar (@_);
    unless ($params{filername}) {
        $self->error_message("filername not specified in Export->create()");
        return;
    }
    unless ($params{physical_path}) {
        $self->error_message("physical_path not specified in Export->create()");
        return;
    }

    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());

    my $export = SDM::Disk::Export->get( filername => $params{filername}, physical_path => $params{physical_path} );
    if (defined $export) {
        $self->warning_message("Export already exists: " . $params{filername} . " " . $params{physical_path} );
        return;
    }
    my $filer = SDM::Disk::Filer->get_or_create( name => $params{filername} );
    if (! defined $filer) {
        $self->warning_message("Filer '" . $params{filername} . "' does not exist and adding it failed.");
        return;
    }
    return $self->SUPER::create( %params );
}

1;