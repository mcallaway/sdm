
package Sdm::Disk::Volume::Set::View::Table::Json;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Volume::Set::View::Table::Json{
    is => 'UR::Object::Set::View::Default::Json',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'json',
                    subject_class_name => 'Sdm::Disk::Volume',
                    aspects => [
                        'mount_path',
                        'total_kb',
                        'used_kb',
                        'capacity',
                        'disk_group',
                        'filername',
                        'last_modified',
                    ]
                }
            ]
        }
    ]
};

1;