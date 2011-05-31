
package SDM::Disk::Filer::Set::View::Table::Xml;

use strict;
use warnings;

use SDM;

class SDM::Disk::Filer::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'SDM::Disk::Filer',
                    aspects => [
                        'name',
                        'status',
                        'comments',
                        'hostname',
                        'arrayname',
                        'created',
                        'last_modified',
                    ]
                }
            ]
        }
    ]
};
