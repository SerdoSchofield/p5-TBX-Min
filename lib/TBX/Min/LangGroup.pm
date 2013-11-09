#
# This file is part of TBX-Min
#
# This software is copyright (c) 2013 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::Min::LangGroup;
use strict;
use warnings;
use Carp;
our $VERSION = '0.01'; # VERSION

# ABSTRACT: Store information from one TBX-Min C<langGroup> element

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

sub code {
    my ($self, $code) = @_;
    if($code) {
        return $self->{code} = $code;
    }
    return $self->{code};
}

sub term_groups { ## no critic(RequireArgUnpacking)
    my ($self) = @_;
    if (@_ > 1){
        croak 'extra argument found (term_groups is a getter only)';
    }
    return $self->{term_groups};
}

sub add_term_group {
    my ($self, $term_grp) = @_;
    if( !$term_grp || !$term_grp->isa('TBX::Min::TermGroup') ){
        croak 'argument to add_term_group should be a TBx::Min::TermGroup';
    }
    push @{$self->{term_groups}}, $term_grp;
    return;
}


1;

__END__

=pod

=head1 NAME

TBX::Min::LangGroup - Store information from one TBX-Min C<langGroup> element

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use TBX::Min::LangGroup;
    use TBX::Min::TermGroup;
    my $lang_grp = TBX::Min::LangGroup->new(
        {code => 'en'});
    print $lang_grp->lang(); # 'en'
    my $term_grp = TBX::Min::TermGroup->new({term => 'perl'});
    $lang_grp->add_term_group($term_grp);
    my $term_grps = $lang_grp->term_groups;
    print $#$term_grps; # '1'

=head1 DESCRIPTION

This class represents a single language group contained in a TBX-Min file.
A language group is contained by a concept entry, and contains several term
groups each representing a given concept for the same language.

=head1 METHODS

=head2 C<new>

Creates a new C<TBX::Min::LangGroup> instance. Optionally you may pass in
a hash reference which is used to initialize the object. The allowed hash
fields are C<code> and C<term_groups>, where C<code> is the abbreviation of
the language the contained terms belong to, and C<term_groups> is an array
reference containing C<TBX::Min::LangGroup> objects.

=head2 C<code>

Get or set the language group language abbreviation (C<en>, C<de>, etc.).

=head2 C<term_groups>

Returns an array ref containing all of the C<TBX::Min::TermGroup> objects
in this concept entry. The array ref is the same one used to store the objects
internally, so additions or removals from the array will be reflected in future
calls to this method.

=head2 C<add_term_group>

Adds the input C<TBX::Min::TermGroup> object to the list of language groups
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
