
package System::Disk::Filer::Command::QuerySnmp;

use strict;
use warnings;

use System;

# Checking currentness in host_is_current()
use Date::Manip;
use Date::Manip::Date;
# Usage function
use Pod::Find qw(pod_where);
use Pod::Usage;

use File::Basename qw(basename);

# Autoflush
local $| = 1;

class System::Disk::Filer::Command::QuerySnmp {
  is => 'System::Command::Base',
  has_optional => [
    force => {
      is => 'Boolean',
      default => 0,
      doc => 'Query all filers regardless of status',
    },
    allow_mount => {
      is => 'Boolean',
      default => 0,
      doc => 'Allow mounting of filesystems to discover disk groups',
    },
    timeout => {
      is => 'Number',
      default => 15,
      doc => 'Not yet implemented',
    },
    host_maxage => {
      is => 'Number',
      default => 86400,
      doc => 'max seconds since last check',
    },
    vol_maxage => {
      is => 'Number',
      default => 15,
      doc => 'max days until volume is considered purgable',
    },
    rrdpath => {
      is => 'Text',
      default => $ENV{SYSTEM_DISK_RRDPATH} ||= "/var/cache/sdm/rrd",
      doc => 'Path to rrd file storage (not yet implemented)',
    },
    purge => {
      is => 'Boolean',
      default => 0,
      doc => 'Purge aged volume entries (not yet implemented)',
    },
    cleanonly => {
      is => 'Boolean',
      default => 0,
      doc => 'Remove volumes from the DB that the Filer no longer exports',
    },
    discover_groups => {
      is => 'Boolean',
      default => 0,
      doc => 'Discover disk groups from touch files on volumes and create them on the fly',
    },
    is_current => {
      is => 'Boolean',
      default => 0,
      doc => 'Check currency status',
    },
    filername => {
      # If I use is => Filer here, UR errors out immediately if the filer doesn't exist.
      # If I use is => Text, then I can use get_or_create to add on the fly, or query them all.
      #is => 'System::Disk::Filer',
      is => 'Text',
      doc => 'SNMP query the named filer',
    },
    physical_path => {
      is => 'Text',
      doc => 'SNMP query the named filer for this export',
    },
    query_paths => {
      is => 'Boolean',
      doc => 'SNMP query the named filer for exports, but not usage',
    },
  ],
  doc => 'Queries volume usage via SNMP',
};

sub help_brief {
    return 'Updates volume usage information';
}

sub help_synopsis {
    return <<EOS
Updates volume usage information
EOS
}

sub help_detail {
    return <<EOS
Updates volume usage information. Blah blah blah details blah.
EOS
}

=head2 update_volumes
Update SNMP data for all Volumes associated with this Filer.
=cut
sub update_volumes {
    my $self = shift;
    my $volumedata = shift;
    my $filername = shift;

    unless ($filername) {
        $self->logger->error(__PACKAGE__ . " update_volumes(): no filer given");
        return;
    }
    unless ($volumedata) {
        $self->logger->warn(__PACKAGE__ . " update_volumes(): filer " . $filername . " returned empty SNMP volumedata");
        return;
    }

    $self->logger->warn(__PACKAGE__ . " update_volumes($filername)");

    unless ($self->physical_path) {
        # QuerySnmp First find and remove volumes in the DB that are not detected on this filer
        # For this filer, find any stored volumes that aren't present in the volumedata retrieved via SNMP.
        # Note that we skip this step if we specified a single physical_path to update.
        foreach my $volume ( System::Disk::Volume->get( filername => $filername ) ) {
            foreach my $path ($volume->physical_path) {
                next unless($path);
                $path =~ s/\//\\\//g;
                # FIXME: do we want to auto-remove like this?
                if ( ! grep /$path/, keys %$volumedata ) {
                    foreach my $m (System::Disk::Mount->get( $volume->id )) {
                        $self->logger->warn(__PACKAGE__ . " delete stale mount for volume " . $volume->id);
                        $m->delete;
                    }
                    # FIXME, check if there are other filers that export it?
                    $self->logger->warn(__PACKAGE__ . " delete volume no longer exported by filer '$filername': " . $volume->id);
                    $volume->delete;
                }
            }
        }
        return 1 if ($self->cleanonly);
    }

    $self->logger->error(__PACKAGE__ . " updating " . scalar(keys %$volumedata) . " volumes");
    foreach my $physical_path (keys %$volumedata) {

        my $mount_path = $volumedata->{$physical_path}->{mount_path};
        if (! defined $mount_path or $mount_path eq '') {
            $self->logger->error(__PACKAGE__ . " skipping volume with incomplete parameters: $physical_path");
            next;
        }

        my $volume = System::Disk::Volume->get_or_create( filername => $filername, physical_path => $physical_path, mount_path => $mount_path );
        unless ($volume) {
            $self->logger->error(__PACKAGE__ . " failed to get_or_create volume: $filername, $physical_path, $mount_path");
            next;
        }
        $self->logger->debug(__PACKAGE__ . " found volume: $filername, $physical_path, $mount_path");

        # Ensure we have the Group before we update this attribute of a Volume
        my $group_name = $volumedata->{$physical_path}->{disk_group};
        if ($group_name) {
            my $group;
            if ($self->discover_groups) {
                $group = System::Disk::Group->get_or_create( name => $volumedata->{$physical_path}->{disk_group} );
            } else {
                $group = System::Disk::Group->get( name => $volumedata->{$physical_path}->{disk_group} );
            }
            unless ($group) {
                $self->logger->error(__PACKAGE__ . " ignoring currently unknown disk group: $group_name");
                next;
            }
        } else {
            $self->logger->warn(__PACKAGE__ . " no group found for $mount_path");
        }

        unless ($volume) {
            $self->logger->error(__PACKAGE__ . " failed to get_or_create volume");
            next;
        }

        foreach my $attr (keys %{ $volumedata->{$physical_path} }) {
           # FIXME: Don't update disk group from filesystem, only the reverse.
           #next if ($attr eq 'disk_group');
           my $p = $volume->__meta__->property($attr);
           # Primary keys are immutable, don't try to update them
           $volume->$attr($volumedata->{$physical_path}->{$attr})
             if (! $p->is_id and $p->is_mutable);
           $volume->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }

    }
    return 1;
}

=head2 update_gpfs_node
Update SNMP data for all GPFS Hosts associated with this Filer.
=cut
sub update_gpfs_node {
    my $self = shift;
    my $hostdata = shift;

    $self->logger->debug(__PACKAGE__ . " update_gpfs_node " . scalar(keys %$hostdata) . " nodes");

    unless ($hostdata) {
        $self->logger->warn(__PACKAGE__ . " empty GPFS node data");
        return;
    }

    foreach my $hostname (keys %$hostdata) {

        my $toss;
        ($hostname,$toss) = split(/\./,$hostname,2);

        my $host = System::Disk::Host->get( hostname => $hostname );
        unless ($host) {
            $self->logger->warn(__PACKAGE__ . " ignoring GPFS node data for unknown host $hostname");
            next;
        }
        my $node = System::Disk::GpfsNode->get_or_create( gpfsNodeName => $hostname );

        unless ($node) {
            $self->logger->error(__PACKAGE__ . " failed to get_or_create gpfsNode entry");
            return;
        }

        foreach my $attr (keys %{ $hostdata->{$hostname} }) {
           my $p = $node->__meta__->property($attr);
           # Primary keys are immutable, don't try to update them
           $node->$attr($hostdata->{$hostname}->{$attr})
             if (! $p->is_id and $p->is_mutable);
           $node->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }

    }
    return 1;
}

=head2 update_gpfs_fs_perf
Update SNMP data for all GPFS Hosts associated with this Filer.
=cut
sub update_gpfs_fs_perf {
    my $self = shift;
    my $gpfsfsdata = shift;

    return unless ($gpfsfsdata);

    $self->logger->debug(__PACKAGE__ . " update_gpfs_fs_perf ". scalar(keys %$gpfsfsdata) . " items");

    foreach my $fsname (keys %$gpfsfsdata) {
        # FIXME: GPFS subAgent reports volumes bare, where hrStorageDescr has /vol prepended.
        # Prepend here so they match.
        $fsname = "/vol/$fsname";

        my $volume = System::Disk::Volume->get( physical_path => $fsname );
        unless ($volume) {
            $self->logger->warn(__PACKAGE__ . " ignoring GPFS filesystem perf data for unknown volume $fsname");
            next;
        }
        my $fs = System::Disk::GpfsFsPerf->get_or_create( gpfsFileSystemPerfName => $fsname, volume_id => $volume->id );
        unless ($fs) {
            $self->logger->error(__PACKAGE__ . " failed to get_or_create gpfsFileSystemPerfName entry");
            next;
        }

        foreach my $attr (keys %{ $gpfsfsdata->{$fsname} }) {
            my $p = $fs->__meta__->property($attr);
            # Primary keys are immutable, don't try to update them
            $fs->$attr($gpfsfsdata->{$fsname}->{$attr})
                if (! $p->is_id and $p->is_mutable);
            $fs->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }
        $self->logger->debug(__PACKAGE__ . " updated $fsname");

    }
    return 1;
}

=head2 update_gpfs_disk_perf
Update SNMP data for all GPFS Hosts associated with this Filer.
=cut
sub update_gpfs_disk_perf {
    my $self = shift;
    my $gpfsdiskdata = shift;

    return unless ($gpfsdiskdata);

    $self->logger->warn(__PACKAGE__ . " update_gpfs_disk_perf " . scalar(keys %$gpfsdiskdata) . " items");

    while (my ($lun,$hashdata) =  each %$gpfsdiskdata) {
        # Keys here have several components we can chop off.
        # Remake the hash table with the shorter keys.
        while (my ($k,$v) = each %$hashdata) {
            my ($oid,$toss) = split(/\./,$k,2);
            $hashdata->{$oid} = $v;
            delete $hashdata->{$k};
        }
        $gpfsdiskdata->{$lun} = $hashdata;
    }

    while (my ($lun,$hashdata) =  each %$gpfsdiskdata) {
        my $fsname = $gpfsdiskdata->{$lun}->{'gpfsDiskPerfFSName'};
        # FIXME: GPFS subAgent reports volumes bare, where hrStorageDescr has /vol prepended.
        # Prepend here so they match.
        unless ($fsname) {
            $self->logger->error(__PACKAGE__ . " no gpfsDiskPerfFSName (Volume) for $lun");
            next;
        }
        $fsname = "/vol/$fsname";

        my $volume = System::Disk::Volume->get( physical_path => $fsname );
        unless ($volume) {
            $self->logger->warn(__PACKAGE__ . " ignoring GPFS disk perf data for $lun using unknown volume $fsname");
            next;
        }
        my $fs = System::Disk::GpfsDiskPerf->get_or_create( gpfsDiskPerfFSName => $fsname, volume_id => $volume->id );
        unless ($fs) {
            $self->logger->error(__PACKAGE__ . " failed to get_or_create gpfsDiskPerfFSName entry");
            next;
        }

        while (my ($attr,$value) = each %$hashdata) {
            my $p = $fs->__meta__->property($attr);
            unless ($p) {
                $self->logger->error(__PACKAGE__ . " failed to find $attr for GpfsDiskPerf object");
                next;
            }
            # Primary keys are immutable, don't try to update them
            $fs->$attr($value)
                if (! $p->is_id and $p->is_mutable);
            $fs->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }
        $self->logger->debug(__PACKAGE__ . " updated $fsname using $lun");
    }
}


=head2 purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and warn on all stale volumes.
=cut
sub validate_volumes {
    my $self = shift;
    $self->logger->error(__PACKAGE__ . " max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->logger->error(__PACKAGE__ . " max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (System::Disk::Volume->get( filername => $self->name )) {
        $volume->validate($self->vol_maxage);
    }
}

=head2 purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and purge all stale volumes.
=cut
sub purge_volumes {
    my $self = shift;
    $self->logger->error(__PACKAGE__ . " max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->logger->error(__PACKAGE__ . " max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (System::Disk::Volume->get( filername => $self->name )) {
        $volume->purge($self->vol_maxage);
    }
}

=head2 _query_snmp
The SNMP bits of execute()
=cut
sub _query_snmp {
    my $self = shift;
    my $filer = shift;

    # Just check if Filer is_current
    $self->logger->warn(__PACKAGE__ . " running SNMP query on filer " . $filer->name);
    if ($self->is_current) {
        if ($filer->is_current($self->host_maxage)) {
            $self->logger->warn(__PACKAGE__ . " filer " . $filer->name . " is current");
        } else {
            $self->logger->warn(__PACKAGE__ . " filer " . $filer->name . " is NOT current, last check: " . $filer->last_modified);
        }
        next;
    }

    # Update Filer data that are not current
    my $is_gpfs;
    my $volumedata = {};
    my $gpfsfsdata = {};
    my $gpfsdiskdata = {};
    my $gpfsnodedata = {};
    eval {
        my @params = ( loglevel => $self->loglevel, hostname => $filer->name );
        if ($self->discover_groups) {
            # Tell the snmp utility it's ok to mount to look for disk groups
            # FIXME: site specific for nfs automounter
            push @params, ( allow_mount => $self->allow_mount );
        }
        my $snmp = System::Utility::SNMP::DiskUsage->create( @params );

        # Query SNMP for disk usage numbers
        $volumedata = $snmp->acquire_volume_data();

        # If Linux and GPFS, get GPFS tables too.
        if ($snmp->hosttype eq 'linux') {
            # For a GPFS cluster, determine which host is the master in the cluster, and
            # query it for GPFS cluster data.
            $is_gpfs = $snmp->detect_gpfs;
            if ($ENV{SYSTEM_DISK_GPFS_PRESENT} and $is_gpfs) {
                foreach my $host ( $filer->host) {
                    if ($host->master) {
                        $self->logger->debug(__PACKAGE__ . " query gpfs master node " . $host->hostname);
                        $snmp->hostname($host->hostname);
                        $snmp->command('snmpwalk');
                        $gpfsnodedata = $snmp->read_snmp_into_table('gpfsNodeStatusTable');
                        $gpfsfsdata = $snmp->read_snmp_into_table('gpfsFileSystemPerfTable');
                        $gpfsdiskdata = $snmp->read_snmp_into_table('gpfsDiskPerfTable');
                        last;
                    } else {
                        $self->logger->debug(__PACKAGE__ . " gpfs node " . $host->hostname . " is not a master");
                    }
                }
            }
        }

        $snmp->delete();
        $filer->status(1);
        $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
    };
    if ($@) {
        # log here, but not high priority, it's common
        $self->logger->warn(__PACKAGE__ . "error with SNMP query: $@");
        $filer->status(0);
    }

    # Generic Volume data
    $self->update_volumes( $volumedata, $filer->name );

    if ($ENV{SYSTEM_DISK_GPFS_PRESENT} and $is_gpfs) {
        # Updating GPFS node data must come after update_volumes
        $self->update_gpfs_node( $gpfsnodedata );
        $self->update_gpfs_fs_perf( $gpfsfsdata );
        $self->update_gpfs_disk_perf( $gpfsdiskdata );
    }
}

=head2 execute
Execute QuerySnmp() queries SNMP on a named Filer and stores disk usage information.
=cut
sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my @filers;
    if (defined $self->filername) {
        # FIXME: should this be a get(), do we want to allow transparently adding Filers?
        #@filers = System::Disk::Filer->get_or_create( name => $self->filername );
        @filers = System::Disk::Filer->get( name => $self->filername );
    } else {
        if ($self->force) {
            # If "force", get all Filers and query them even if status is 0.
            @filers = System::Disk::Filer->get();
        } else {
            # Query all filers that have status => 1...
            # This is what we use for a cron job.
            @filers = System::Disk::Filer->get( status => 1 );
        }
    }

    # Allow the ability to update a single physical_path on a filer.
    if (defined $self->physical_path) {
        unless ($self->filername) {
            $self->logger->error(__PACKAGE__ . " specify a filer to query for physical_path: " . $self->physical_path);
            return;
        }
    }

    unless (scalar @filers) {
        $self->logger->warn(__PACKAGE__ . " no filers to be scanned. Consider using --force.");
    }

    foreach my $filer (@filers) {
        $self->_query_snmp($filer);
    }

    # Now update disk group RRD files.
    #my $rrd = System::Utility::DiskGroupRRD->create( loglevel => $self->loglevel );
    #$rrd->run();

    return 1;
}

1;
