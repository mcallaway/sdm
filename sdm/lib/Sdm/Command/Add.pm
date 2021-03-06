package Sdm::Command::Add;

use strict;
use warnings;

use Sdm;

require Carp;
use Data::Dumper 'Dumper';

class Sdm::Command::Add {
    is => 'Sdm::Command::Base',
    is_abstract => 1,
    doc => 'CRUD add command class.',
};

sub _target_class { Carp::confess('Please use CRUD or implement _target_class in '.$_[0]->class); }
sub _name_for_objects { Carp::confess('Please use CRUD or implement _name_for_objects in '.$_[0]->class); }

sub sub_command_sort_position { .1 };

sub help_brief {
    return 'add new '.$_[0]->_name_for_objects;
}

sub help_detail {
    return 'add new '.$_[0]->_name_for_objects;
}

sub execute {
    my $self = shift;

    #$self->status_message('Add'.$self->_name_for_objects);

    my $class = $self->class;
    my @properties = grep { $_->class_name eq $class } $self->__meta__->property_metas;
    my %attrs;
    for my $property ( @properties ) {
        my $property_name = $property->property_name;
        my @values;
        @values = $self->$property_name;
        next if not defined $values[0];
        if ( $property->is_many ) {
            $attrs{$property_name} = \@values;
        }
        else {
            $attrs{$property_name} = $values[0];
        }
    }
    #$self->status_message(Dumper(\%attrs));

    # Find out if we already have an Object whose id matches that which we are about to create
    my $target_class = $self->_target_class;
    my $id = pop @{ [ grep { $_->is_id } $target_class->__meta__->property_metas ] };
    if ($id) {
        my $res = $target_class->get( $id->property_name => $attrs{$id->property_name} );
        if ($res) {
            $self->error_message("'$target_class' object already exists with this id: " . $attrs{$id->property_name} );
            return;
        }
    }
    my $obj = $target_class->create(%attrs);
    if ( not $obj ) {
        $self->error_message('Could not create '.$target_class);
        return;
    }

    $self->status_message('Created: '.$obj->id);

    return 1;
}

1;
