package TBX::Min::TermGroup;
use strict;
use warnings;
use parent 'Class::Accessor';
TBX::Min::TermGroup->mk_accessors(qw(
    term
    part_of_speech
    note
    customer
    status
));
# VERSION

# ABSTRACT: Store information from one TBX-Min C<termGroup> element
=head1 SYNOPSIS

    use TBX::Min::TermGroup;
    my $termGrp = TBX::Min::TermGroup->new(
        {term => 'bat signal', status => "preferred"});
    $term_grp->part_of_speech('noun');
    $term_grp->customer('GCPD');
    print $term_grp->term; # 'bat signal'

=head1 DESCRIPTION

This class represents a single term group contained in a TBX-Min file. A term
group contains a single term and information pertaining to it, such as part of
speech, a note, or the associated customer.

=cut

=head1 METHODS

=head2 C<new>

Creates a new C<TBX::Min::TermGroup> instance. Optionally you may pass in a hash
reference which is used to initialized the object. The fields of the hash
correspond to the names of the accessor methods listed below.

=head2 C<term>

Get or set the term text associated with this term group.

=head2 C<part_of_speech>

Get or set the part of speech associated with this term group.

=head2 C<note>

Get or set a note associated with this term group.

=head2 C<customer>

Get or set a customer associated with this term group.

=head2 C<status>

Get or set a status  associated with this term group.

=head1 SEE ALSO

L<TBX::Min>

=cut

1;