package System::Disk::Host::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Host::Command::Create {
    is => 'System::Command::Base',
    has => [
        hostname      => { is => 'VARCHAR(255)' },
        filer         => { is => 'VARCHAR(255)' },
    ],
    has_optional => [
        comments      => { is => 'VARCHAR(255)' },
        location      => { is => 'VARCHAR(255)' },
        os            => { is => 'VARCHAR(255)' },
        status        => { is => 'UNSIGNED INTEGER', default => 0 },
    ],
};

sub help_brief {
    return 'Creates a host';
}

sub help_synopsis {
    return <<EOS
Creates a host
EOS
}

sub help_detail {
    return <<EOS
This tool creates a host.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    # FIXME: Is there a way in one statement to map params to $self->attributes
    my %params = (
        hostname => $self->hostname,
        filer    => $self->filer,
        comments => $self->comments,
        location => $self->location,
        status => $self->status,
        os => $self->os,
    );

    eval {
      System::Disk::Host->create(%params);
    };
    if ($@) {
        Carp::confess "Could not create host: $@";
    }

    return 1;
}

1;
