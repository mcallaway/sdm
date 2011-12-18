
package Sdm::Object::Set::View::Table::Json;

use strict;
use warnings;

use Sdm;

class Sdm::Object::Set::View::Table::Json {
    is => 'UR::Object::Set::View::Default::Json',
    has_constant => [
        # Empty default aspects and calculate them on the fly based on subject attributes below
        default_aspects => {
            value => []
        }
    ]
};

sub _generate_content {
    my $self = shift;
    return $self->_json->allow_blessed->encode($self->_jsobj);
}

=head2 _jsobj
Override the normal JSON object with one suitable for jQuery DataTables.
We do this because we're bypassing the XSL layer expected by UR.
=cut
sub _jsobj {
    my $self = shift;

    my $subject = $self->subject();
    return '' unless $subject =~ /::Set/;

    my @aData;
    foreach my $member ($subject->members) {
        my %args = (
            subject_class_name => $self->subject_class_name,
            perspective => 'default',
            toolkit => 'json',
        );

        # Use our default_aspects if we have them defined.
        my @default_aspects = @{ $self->default_aspects };
        unless (@default_aspects) {
            # Otherwise, make them the attributes of our subject.
            @default_aspects = map { $_->property_name } $member->__meta__->properties;
        }
        @default_aspects = grep {!/id/} @default_aspects;
        unshift @default_aspects, 'id';
        $args{aspects} = [ @default_aspects ];
        my $v = $member->create_view(%args);
        my @data = $v->aspects;
        @data = map { $v->_generate_content_for_aspect($_) } @data;
        push @aData, [ @data ] ;
    }

    my $jsobj = {
        aaData => [ @aData ],
        iTotalRecords => $subject->count,
        iTotalDisplayRecords => $subject->count,
        sEcho => 1,
    };

    return $jsobj;
}

1;