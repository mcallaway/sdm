
package SDM::Asset::Hardware;

use SDM;

class SDM::Asset::Hardware {
    schema_name => 'Asset',
    data_source => 'SDM::DataSource::Asset',
    table_name => 'asset_hardware',
    id_generator => '-uuid',
    id_by => {
        id => {
            is => 'Text',
            doc => 'The generated UUID id for hardware'
        }
    },
    has_optional => [
        manufacturer  => { is => 'Text' },
        model         => { is => 'Text' },
        serial        => { is => 'Text' },
        description   => { is => 'Text' },
        comments      => { is => 'Text' },
        location      => { is => 'Text' },
        created       => { is => 'Date' },
        last_modified => { is => 'Date' },
    ]
};

sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

1;