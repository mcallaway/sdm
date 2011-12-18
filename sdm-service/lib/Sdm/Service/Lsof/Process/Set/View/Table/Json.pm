
package Sdm::Service::Lsof::Process::Set::View::Table::Json;

use strict;
use warnings;

use Sdm;

class Sdm::Service::Lsof::Process::Set::View::Table::Json {
    is => 'UR::Object::Set::View::Default::Json',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'json',
                    subject_class_name => 'Sdm::Service::Lsof::Process',
                    aspects => [
                        'hostname',
                        'pid',
                        'command',
                        'username',
                        'uid',
                        'age',
                        'nfsd',
                        'filename',
                        #{
                        #    name => 'files',
                        #    aspects => [
                        #        'filename',
                        #    ],
                        #    perspective => 'default',
                        #    toolkit => 'json',
                        #    subject_class_name => 'Sdm::Service::Lsof::File',
                        #},
                        'created',
                        'last_modified'
                    ]
                }
            ]
        }
    ]
};

1;