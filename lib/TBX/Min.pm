#
# This file is part of TBX-Min
#
# This software is copyright (c) 2013 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::Min;
use strict;
use warnings;
use XML::Twig;
use autodie;
use Path::Tiny;
use Carp;
use TBX::Min::ConceptEntry;
use TBX::Min::LangGroup;
use TBX::Min::TermGroup;
use XML::Writer;
our $VERSION = '0.01'; # VERSION

unless (caller){
	use Data::Dumper;
	print Dumper __PACKAGE__->new(@ARGV);

}

# ABSTRACT: Read, write and edit TBX-Min files

sub new_from_xml {
	my ($class, $data) = @_;

	my $fh = _get_handle($data);

	# build a twig out of the input document
	my $twig = XML::Twig->new(
		# pretty_print    => 'nice', #this seems to affect other created twigs, too
		# output_encoding => 'UTF-8',
		# do_not_chain_handlers => 1, #can be important when things get complicated
		keep_spaces		=> 0,
		TwigHandlers    => {
            TBX => \&_tbx,
			# header attributes become attributes of the TBX::Min object
			title => \&_headerAtt,
			subjectField => \&_subjectField,
			origin => \&_headerAtt,
			license => \&_headerAtt,
			directionality => \&_headerAtt,
			languages => \&_languages,

			# these become attributes of the current TBX::Min::TermGroup object
			term => sub {shift->{tbx_min_current_term_grp}->term($_->text)},
			partOfSpeech => sub {
				shift->{tbx_min_current_term_grp}->part_of_speech($_->text)},
			note => sub {shift->{tbx_min_current_term_grp}->note($_->text)},
			customer => sub {
				shift->{tbx_min_current_term_grp}->customer($_->text)},
			termStatus => sub {
				shift->{tbx_min_current_term_grp}->status($_->text)},
		},
		start_tag_handlers => {
			conceptEntry => \&_conceptStart,
			langGroup => \&_langStart,
			termGroup => \&_termGrpStart,
		}
	);

	# use handlers to process individual tags, then grab the result
	$twig->parse($fh);
	my $self = $twig->{tbx_min_att};
	$self->{concepts} = $twig->{tbx_min_concepts};
	bless $self, $class;
	return $self;
}

sub _get_handle {
    my ($data) = @_;
    my $fh;
    if((ref $data) eq 'SCALAR'){
        open $fh, '<', $data; ## no critic(RequireBriefOpen)
    }else{
        $fh = path($data)->filehandle('<');
    }
    return $fh;
}

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

sub title {
    my ($self, $title) = @_;
    if($title) {
        return $self->{title} = $title;
    }
    return $self->{title};
}

sub origin {
    my ($self, $origin) = @_;
    if($origin) {
        return $self->{origin} = $origin;
    }
    return $self->{origin};
}

sub license {
    my ($self, $license) = @_;
    if($license) {
        return $self->{license} = $license;
    }
    return $self->{license};
}

sub directionality {
    my ($self, $directionality) = @_;
    if($directionality) {
        return $self->{directionality} = $directionality;
    }
    return $self->{directionality};
}

sub source_lang {
    my ($self, $source_lang) = @_;
    if($source_lang) {
        return $self->{source_lang} = $source_lang;
    }
    return $self->{source_lang};
}

sub target_lang {
    my ($self, $target_lang) = @_;
    if($target_lang) {
        return $self->{target_lang} = $target_lang;
    }
    return $self->{target_lang};
}

sub doc_lang {
    my ($self, $doc_lang) = @_;
    if($doc_lang) {
        return $self->{doc_lang} = $doc_lang;
    }
    return $self->{doc_lang};
}

sub concepts { ## no critic(RequireArgUnpacking)
    my ($self) = @_;
    if (@_ > 1){
        croak 'extra argument found (concepts is a getter only)';
    }
    return $self->{concepts};
}

sub add_concept {
    my ($self, $concept) = @_;
    if( !$concept || !$concept->isa('TBX::Min::ConceptEntry') ){
        croak 'argument to add_concept should be a TBx::Min::ConceptEntry';
    }
    push @{$self->{concepts}}, $concept;
    return;
}

sub as_xml {
    my ($self) = @_;
    my $xml;
    my $writer = XML::Writer->new(
        OUTPUT => \$xml, NEWLINES => 1, ENCODING => 'utf-8');
    $writer->startTag('TBX', dialect => 'TBX-Min',
        $self->doc_lang ? ('xml:lang' => $self->doc_lang) : ());

    $writer->startTag('header');
    for my $header_att (qw(title origin license directionality)){
        next unless $self->{$header_att};
        $writer->startTag($header_att);
        $writer->characters($self->{$header_att});
        $writer->endTag;
    }
    if($self->{source_lang} || $self->{target_lang}){
        my @atts;
        push @atts, (source => $self->{source_lang}) if $self->{source_lang};
        push @atts, (target => $self->{target_lang}) if $self->{target_lang};
        $writer->emptyTag('languages', @atts);
    }
    $writer->endTag; # header

    $writer->startTag('body');

    for my $concept (@{$self->concepts}){
        $writer->startTag('conceptEntry',
            $concept->id ? (id => $concept->id) : ());
        if(my $sf = $concept->subject_field){
            $writer->startTag('subjectField');
            $writer->characters($sf);
            $writer->endTag;
        }
        for my $langGrp (@{$concept->lang_groups}){
            $writer->startTag('langGroup',
                $langGrp->code ? ('xml:lang' => $langGrp->code) : () );
            for my $termGrp (@{$langGrp->term_groups}){
                $writer->startTag('termGroup');

                if (my $term = $termGrp->term){
                    $writer->startTag('term');
                    $writer->characters($term);
                    $writer->endTag; # term
                }

                if (my $customer = $termGrp->customer){
                    $writer->startTag('customer');
                    $writer->characters($customer);
                    $writer->endTag; # customer
                }

                if (my $note = $termGrp->note){
                    $writer->startTag('note');
                    $writer->characters($note);
                    $writer->endTag; # note
                }

                if (my $status = $termGrp->status){
                    $writer->startTag('termStatus');
                    $writer->characters($status);
                    $writer->endTag; # termStatus
                }

                if (my $pos = $termGrp->part_of_speech){
                    $writer->startTag('partOfSpeech');
                    $writer->characters($pos);
                    $writer->endTag; # partOfSpeech
                }

                $writer->endTag; # termGroup
            }
            $writer->endTag; # langGroup
        }
        $writer->endTag; # conceptEntry
    }

    $writer->endTag; # body

    $writer->endTag; # TBX
    $writer->end;
    return $xml;
}

######################
### XML TWIG HANDLERS
######################
# all of the twig handlers store state on the XML::Twig object. A bit kludgy,
# but it works.

sub _tbx {
    my ($twig, $_) = @_;
    if(my $lang = $_->att('xml:lang')){
        $twig->{tbx_min_att}->{doc_lang} = $lang;
    }
    return 1;
}

sub _headerAtt{
	my ($twig, $_) = @_;
	${ $twig->{'tbx_min_att'} }{_decamel($_->name)} = $_->text;
	return 1;
}

# turn camelCase into camel_case
sub _decamel {
	my ($camel) = @_;
	$camel =~ s/([A-Z])/_\l$1/g;
	return $camel;
}

sub _languages{
	my ($twig, $_) = @_;
	if(my $source = $_->att('source')){
		${ $twig->{'tbx_min_att'} }{'source_lang'} = $source;
	}
	if(my $target = $_->att('target')){
		${ $twig->{'tbx_min_att'} }{'target_lang'} = $target;
	}
	return 1;
}

# add a new concept entry to the list of those found in this file
sub _conceptStart {
	my ($twig, $node) = @_;
	my $concept = TBX::Min::ConceptEntry->new();
	if($node->att('id')){
		$concept->id($node->att('id'));
	}else{
		carp 'found conceptEntry missing id attribute';
	}
	push @{ $twig->{tbx_min_concepts} }, $concept;
	return 1;
}

#just set the subject_field of the current concept
sub _subjectField {
	my ($twig, $node) = @_;
    $twig->{tbx_min_concepts}->[-1]->
        subject_field($node->text);
    return 1;
}

# Create a new LangGroup, add it to the current concept,
# and set it as the current LangGroup.
sub _langStart {
    my ($twig, $node) = @_;
	my $lang = TBX::Min::LangGroup->new();
	if($node->att('xml:lang')){
		$lang->code($node->att('xml:lang'));
	}else{
		carp 'found langGroup missing xml:lang attribute';
	}

	$twig->{tbx_min_concepts}->[-1]->add_lang_group($lang);
	$twig->{tbx_min_current_lang_grp} = $lang;
	return 1;
}

# Create a new termGroup, add it to the current langGroup,
# and set it as the current termGroup.
sub _termGrpStart {
	my ($twig) = @_;
	my $term = TBX::Min::TermGroup->new();
	$twig->{tbx_min_current_lang_grp}->add_term_group($term);
	$twig->{tbx_min_current_term_grp} = $term;
	return 1;
}

1;

__END__

=pod

=head1 NAME

TBX::Min - Read, write and edit TBX-Min files

=head1 VERSION

version 0.01

=head1 SYNOPSIS

	use TBX::Min;
	my $min = TBX::Min->new('/path/to/file.tbx');
	my $concepts = $min->concepts;

=head1 DESCRIPTION

TBX-Min is a minimal, DCT-style dialect of TBX. This module
allows you to read, write and edit the contents of TBX-Min
data.

=head1 METHODS

=head2 C<new_from_xml>

Creates a new instance of TBX::Min. The single argument should be either a
string pointer containing the TBX-Min XML data or the name of the file
containing this data is required.

=head2 C<new>

Creates a new C<TBX::Min> instance. Optionally you may pass in
a hash reference which is used to initialize the object. The allowed hash
fields are C<title>, C<origin>, C<license>, C<directionality>, C<source_lang>
and C<target_lang>, which correspond to methods of the same name, and
C<concepts>, which should be an array reference containing
C<TBX::Min::ConceptEntry> objects.

=head2 C<title>

Get or set the document title.

=head2 C<origin>

Get or set the document origin string (a note about or the title of the
document's origin).

=head2 C<license>

Get or set the document license string.

=head2 C<directionality>

Get or set the document directionality string. This string represents
the direction of translation this document is designed for.

=head2 C<source_lang>

Get or set the document source language (abbreviation) string.

=head2 C<target_lang>

Get or set the document target language (abbreviation) string.

=head2 C<doc_lang>

Get or set the language used in the document outside of C<LangGroup>
contents (such as in the title or origin strings.) This should be an
abbreviation such as "en".

=head2 C<concepts>

Returns an array ref containing the C<TBX::Min::ConceptEntry> objects contained
in the document.The array ref is the same one used to store the objects
internally, so additions or removals from the array will be reflected in future
calls to this method.

=head2 C<add_concept>

Adds the input C<TBX::Min::LangGroup> object to the list of language groups
contained by this object.

=head2 C<as_xml>

Returns a string pointer containing an XML representation of this TBX-Min
document.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
