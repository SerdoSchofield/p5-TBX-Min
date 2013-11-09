#
# This file is part of TBX-Min
#
# This software is copyright (c) 2013 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::Min::ConceptEntry;
use strict;
use warnings;
use Carp;
our $VERSION = '0.01'; # VERSION

# ABSTRACT: Store information from one TBX-Min C<conceptEntry> element

sub new {
    my ($class, $args) = @_;
    my $self;
    if((ref $args) eq 'HASH'){
        $self = $args;
    }else{
        $self = {};
    }
    return bless $self, $class;
}

sub id {
    my ($self, $id) = @_;
    if($id) {
        return $self->{id} = $id;
    }
    return $self->{id};
}

sub subject_field {
    my ($self, $subject_field) = @_;
    if($subject_field) {
        return $self->{subject_field} = $subject_field;
    }
    return $self->{subject_field};
}

sub lang_groups { ## no critic(RequireArgUnpacking)
    my ($self) = @_;
    if (@_ > 1){
        croak 'extra argument found (lang_groups is a getter only)';
    }
    return $self->{lang_groups};
}

sub add_lang_group {
    my ($self, $lang_grp) = @_;
    if( !$lang_grp || !$lang_grp->isa('TBX::Min::LangGroup') ){
        croak 'argument to add_lang_group should be a TBx::Min::LangGroup';
    }
    push @{$self->{lang_groups}}, $lang_grp;
    return;
}


1;

__END__

=pod

=head1 NAME

TBX::Min::ConceptEntry - Store information from one TBX-Min C<conceptEntry> element

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use TBX::Min::ConceptEntry;
    use TBX::Min::LangGroup;
    my $concept = TBX::Min::ConceptEntry->new(
        {id => 'B001'});
    print $concept->id(); # 'B001'
    my $lang_grp = TBX::Min::LangGroup->new({code => 'en'});
    $concept->add_lang_group($lang_grp);
    my $lang_grps = $concept->lang_groups;
    print $#$lang_grps; # '1'

=head1 DESCRIPTION

This class represents a single concept entry contained in a TBX-Min file. A
concept entry contains several language groups, each containing terms that
represent this concept in a given languages.

=head1 METHODS

=head2 C<new>

Creates a new C<TBX::Min::ConceptEntry> instance. Optionally you may pass in
a hash reference which is used to initialize the object. The allowed hash
fields are C<id>, C<subject_field> and C<lang_groups>, where C<id> and
C<subject_field> correspond to methods of the same name, and C<langGroups> is
an array reference containing C<TBX::Min::LangGroup> objects.

=head2 C<id>

Get or set the concept entry id value.

=head2 C<subject_field>

Get or set the concept subject field string.

=head2 C<lang_groups>

Returns an array ref containing all of the C<TBX::Min::LangGroup> objects
in this concept entry. The array ref is the same one used to store the objects
internally, so additions or removals from the array will be reflected in future
calls to this method.

=head2 C<add_lang_group>

Adds the input C<TBX::Min::LangGroup> object to the list of language groups
contained by this object.

=head1 SEE ALSO

L<TBX::Min>

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
