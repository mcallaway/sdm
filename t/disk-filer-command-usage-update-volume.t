
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More tests => 1;
use Test::Exception;

my $command = System::Disk::Filer::Command::Usage->create();
$command->prepare_logger();
$command->{logger}->level($DEBUG);
my $filer = System::Disk::Filer->get( name => 'nfs11' );
my $result = { '/vol/sata812' => {
                        'total_kb' => 6438990688,
                        'disk_group' => 'PRODUCTION_SOLID',
                        'mount_path' => '/gscmnt/sata812',
                        'used_kb' => 5722964896,
                        'physical_path' => '/vol/sata812'
                      },
};
lives_ok { $command->update_volume($filer,$result); } "usage->update_volume: runs ok";
UR::Context->commit();
my $volume = System::Disk::Volume->get( filername => 'nfs11', physical_path => '/vol/sata812' );
ok( $volume->total_kb == 6438990688, "total_kb matches" );
ok( $volume->used_kb == 5722964896, "used_kb matches" );
ok( $volume->disk_group eq 'PRODUCTION_SOLID', "disk_group matches" );
ok( $volume->mount_path eq '/gscmnt/sata812', "mount_path matches" );
ok( $volume->physical_path eq '/vol/sata812', "physical_path matches" );
