
package System::View::Rrd::Html;

use strict;
use warnings;

use System;

class System::View::Rrd::Html {
    is => 'UR::Object::View::Default::Html'
};

=head2 _generate_content
This returns an HTML page for a disk group status RRD trend graph.
This is part of Diskstatus/Html.pm.
=cut
sub _generate_content {
    my $self = shift;
    __FILE__ =~ /^(.*\/System\/).*/;
    my $base = $1;
    my $html = $base . "/View/Resource/Html/html/rrd.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
warn "html $html";
    return $content;
}

1;
