package System::Disk::Filer::Command;

use strict;
use warnings;

use System;

class System::Disk::Filer::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk filers',
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Filer',
    target_name => 'filer',
    list => { show => 'name,status,comments,hostname,arrayname' }
);

1;