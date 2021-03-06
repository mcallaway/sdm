
package Sdm::Site;

use strict;
use warnings;

BEGIN {
    if (my $config = $ENV{SDM_CONFIG}) {
        # call the specified configuration module;
        eval "use $config";
        die $@ if $@;
    } else {
        # look for a config module matching all or part of the hostname.
        use Sys::Hostname;
        my $hostname = Sys::Hostname::hostname();
        my @hwords = reverse split('\.',$hostname);
        while (@hwords) {
            my $pkg = 'Sdm::Site::' . join("::",@hwords);
            local $SIG{__DIE__};
            local $SIG{__WARN__};
            eval "use $pkg";
            if ($@) {
                pop @hwords;
                next;
            }
            else {
                last;
            }
        }
    }
}

# This module potentially conflicts to the perl-supplied Config.pm if you've
# set up your @INC or -I options incorrectly.  For example, you used -I /path/to/modules/Sdm/
# instead of -I /path/to/modules/.  Many modules use the real Config.pm to get info and
# you'll get wierd failures if it loads this module instead of the right one.
{
    my @caller_info = caller(0);
    if ($caller_info[3] eq '(eval)' and $caller_info[6] eq 'Config.pm') {
        die "package Sdm::Config was loaded from a 'use Config' statement, and is not want you wanted.  Are your \@INC and -I options correct?";
    }
}

1;

=pod

=head1 NAME

Sdm::Site - hostname oriented site-based configuration

=head1 DESCRIPTION

Use the fully-qualified hostname to look up site-based configuration.

=head1 AUTHORS

This software is developed by the analysis and engineering teams at The Genome
Institute at Washington Univiersity in St. Louis, with funding from the
National Human Genome Research Institute.

=head1 LICENSE

This software is copyright Washington University in St. Louis.  It is released under
the Lesser GNU Public License (LGPL) version 3.  See the associated LICENSE file in
this distribution.

=head1 BUGS

For defects with any software in the genome namespace,
contact genome-dev@genome.wustl.edu.

=cut

