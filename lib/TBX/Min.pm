package TBX::Min;
use strict;
use warnings;
use XML::Twig;
use autodie;
use Path::Tiny;
use Carp;
use TBX::Min::Entry;
use TBX::Min::LangGroup;
use TBX::Min::TermGroup;
use DateTime::Format::ISO8601;
use Try::Tiny;
# VERSION

# ABSTRACT: Read, write and edit TBX-Min files
=head1 SYNOPSIS

    use TBX::Min;
    my $min = TBX::Min->new('/path/to/file.tbx');
    my $entries = $min->entries;

=head1 DESCRIPTION

TBX-Min is a minimal, DCT-style dialect of TBX. This module
allows you to read, write and edit the contents of TBX-Min
data.

=cut

=head1 METHODS

=head2 C<new_from_xml>

Creates a new instance of TBX::Min. The single argument should be either a
string pointer containing the TBX-Min XML data or the name of the file
containing this data is required.

=cut
sub new_from_xml {
    my ($class, $data) = @_;

    if(!$data){
        croak 'missing required data argument';
    }

    my $fh = _get_handle($data);

    # build a twig out of the input document
    my $twig = XML::Twig->new(
        # pretty_print    => 'nice', #this seems to affect other created twigs, too
        # output_encoding => 'UTF-8',
        # do_not_chain_handlers => 1, #can be important when things get complicated
        keep_spaces     => 0,

        # these store new entries, langGroups and termGroups
        start_tag_handlers => {
            entry => \&_conceptStart,
            langGroup => \&_langStart,
            termGroup => \&_termGrpStart,
        },

        TwigHandlers    => {
            TBX => \&_check_dialect,
            # header attributes become attributes of the TBX::Min object
            id => \&_headerAtt,
            description => \&_headerAtt,
            dateCreated => \&_date_created,
            creator => \&_headerAtt,
            license => \&_headerAtt,
            directionality => \&_directionality,
            languages => \&_languages,

            # becomes part of the current TBX::Min::Entry object
            subjectField => sub {
                shift->{tbx_min_entries}->[-1]->subject_field($_->text)},

            # these become attributes of the current TBX::Min::TermGroup object
            term => sub {shift->{tbx_min_current_term_grp}->term($_->text)},
            partOfSpeech => sub {
                shift->{tbx_min_current_term_grp}->part_of_speech($_->text)},
            note => sub {shift->{tbx_min_current_term_grp}->note($_->text)},
            customer => sub {
                shift->{tbx_min_current_term_grp}->customer($_->text)},
            termStatus => sub {
                shift->{tbx_min_current_term_grp}->status($_->text)},
        }
    );

    # use handlers to process individual tags, then grab the result
    $twig->parse($fh);
    my $self = $twig->{tbx_min_att};
    $self->{entries} = $twig->{tbx_min_entries} || [];
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

=head2 C<new>

Creates a new C<TBX::Min> instance. Optionally you may pass in
a hash reference which is used to initialize the object. The allowed hash
fields are C<id>, C<description>, C<date_created>, C<creator>, C<license>,
C<directionality>, C<source_lang> and C<target_lang>, which correspond to
methods of the same name, and C<entries>, which should be an array reference
containing C<TBX::Min::Entry> objects. This method croaks if
C<date_created> is not in ISO 8601 format.

=cut
sub new {
    my ($class, $args) = @_;
    my $self;
    if((ref $args) eq 'HASH'){
        #don't store a plain string for datetime
        if(my $dt_string = $args->{date_created}){
            $args->{date_created} = _parse_datetime($dt_string);
        }
        if(exists $args->{directionality}){
            _validate_dir($args->{directionality});
        }
        $self = $args;
    }else{
        $self = {};
    }
    $self->{entries} ||= [];
    return bless $self, $class;
}

=head2 C<id>

Get or set the document id. This should be a unique string
identifying this glossary.

=cut
sub id {
    my ($self, $id) = @_;
    if($id) {
        return $self->{id} = $id;
    }
    return $self->{id};
}

=head2 C<description>

Get or set the document description.

=cut
sub description {
    my ($self, $description) = @_;
    if($description) {
        return $self->{description} = $description;
    }
    return $self->{description};
}

=head2 C<date_created>

Get or set the the date that the document was created. This should be a
string in ISO 8601 format. This method croaks if C<date_created> is not
in ISO 8601 format.

=cut
sub date_created {
    my ($self, $date_created) = @_;
    if($date_created) {
        return $self->{date_created} =
            _parse_datetime($date_created);
    }
    if(my $dt = $self->{date_created}){
        return $dt->iso8601;
    }
    return;
}

sub _parse_datetime {
    my ($dt_string) = @_;
    my $dt;
    try{
        $dt = DateTime::Format::ISO8601->parse_datetime($dt_string);
    }catch{
        croak 'date is not in ISO8601 format';
    };
    return $dt;
}

=head2 C<creator>

Get or set the name of the document creator.

=cut
sub creator {
    my ($self, $creator) = @_;
    if($creator) {
        return $self->{creator} = $creator;
    }
    return $self->{creator};
}

=head2 C<license>

Get or set the document license string.

=cut
sub license {
    my ($self, $license) = @_;
    if($license) {
        return $self->{license} = $license;
    }
    return $self->{license};
}

=head2 C<directionality>

Get or set the document directionality string. This string represents
the direction of translation this document is designed for.

=cut
sub directionality {
    my ($self, $directionality) = @_;
    if(defined $directionality) {
        _validate_dir($directionality);
        return $self->{directionality} = $directionality;
    }
    return $self->{directionality};
}

sub _validate_dir {
    my ($dir) = @_;
    if($dir ne 'bidirectional' and $dir ne 'monodirectional'){
        croak "Illegal directionality '$dir'";
    }
    return;
}


=head2 C<source_lang>

Get or set the code representing the document source language. This should
be ISO 639 and 3166 (e.g. C<en-US>, C<de>, etc.).

=cut
sub source_lang {
    my ($self, $source_lang) = @_;
    if($source_lang) {
        return $self->{source_lang} = $source_lang;
    }
    return $self->{source_lang};
}

=head2 C<target_lang>

Get or set the code representing the document target language. This should
be ISO 639 and 3166 (e.g. C<en-US>, C<de>, etc.).

=cut
sub target_lang {
    my ($self, $target_lang) = @_;
    if($target_lang) {
        return $self->{target_lang} = $target_lang;
    }
    return $self->{target_lang};
}

=head2 C<entries>

Returns an array ref containing the C<TBX::Min::Entry> objects contained
in the document.The array ref is the same one used to store the objects
internally, so additions or removals from the array will be reflected in future
calls to this method.

=cut
sub entries { ## no critic(RequireArgUnpacking)
    my ($self) = @_;
    if (@_ > 1){
        croak 'extra argument found (entries is a getter only)';
    }
    return $self->{entries};
}

=head2 C<add_entry>

Adds the input C<TBX::Min::Entry> object to the list of language groups
contained by this object.

=cut
sub add_entry {
    my ($self, $entry) = @_;
    if( !$entry || !$entry->isa('TBX::Min::Entry') ){
        croak 'argument to add_entry should be a TBx::Min::Entry';
    }
    push @{$self->{entries}}, $entry;
    return;
}

=head2 C<as_xml>

Returns a scalar reference containing an XML representation of this
TBX-Min document.

=cut
sub as_xml {
    my ($self) = @_;

    # construct the whole document using XML::Twig::El's
    my $root = XML::Twig::Elt->new(TBX => {dialect => 'TBX-Min'});
    my $header = XML::Twig::Elt->new('header')->paste($root);

    # each of these header elements is a simple element with text
    for my $header_att (
            qw(id creator license directionality description)){
        next unless $self->{$header_att};
        XML::Twig::Elt->new($header_att,
            $self->{$header_att})->paste(last_child => $header);
    }
    if($self->source_lang || $self->target_lang){
        my @atts;
        push @atts, (source => $self->source_lang) if $self->source_lang;
        push @atts, (target => $self->target_lang) if $self->target_lang;
        XML::Twig::Elt->new(languages => {@atts})->paste(
            last_child => $header)
    }
    if(my $dt = $self->{date_created}){
        XML::Twig::Elt->new(dateCreated => $dt->iso8601)->paste(
            last_child => $header);
    }

    my $body = XML::Twig::Elt->new('body')->paste(last_child => $root);
    for my $entry (@{$self->entries}){
        my $entry_el = XML::Twig::Elt->new(
            entry => {$entry->id ? (id => $entry->id) : ()})->
            paste(last_child => $body);
        if(my $sf = $entry->subject_field){
            XML::Twig::Elt->new(subjectField => $sf)->paste(
                last_child => $entry_el);
        }
        for my $langGrp (@{$entry->lang_groups}){
            my $lang_el = XML::Twig::Elt->new(langGroup =>
                {$langGrp->code ? ('xml:lang' => $langGrp->code) : ()}
            )->paste(last_child => $entry_el);
            for my $termGrp (@{$langGrp->term_groups}){
                my $term_el = XML::Twig::Elt->new('termGroup')->paste(
                    last_child => $lang_el);
                if (my $term = $termGrp->term){
                    XML::Twig::Elt->new(term => $term)->paste(
                        last_child => $term_el);
                }

                if (my $customer = $termGrp->customer){
                    XML::Twig::Elt->new(customer => $customer)->paste(
                        last_child => $term_el);
                }

                if (my $note = $termGrp->note){
                    XML::Twig::Elt->new(note => $note)->paste(
                        last_child => $term_el);
                }

                if (my $status = $termGrp->status){
                    XML::Twig::Elt->new(termStatus => $status )->paste(
                        last_child => $term_el);
                }

                if (my $pos = $termGrp->part_of_speech){
                    XML::Twig::Elt->new(partOfSpeech => $pos)->paste(
                        last_child => $term_el);
                }

            } # end termGroup
        } # end langGroup
    } # end entry

    # return pretty-printed string
    XML::Twig->set_pretty_print('indented');
    return \$root->sprint;
}

######################
### XML TWIG HANDLERS
######################

# croak if the user happened to use the wrong dialect of TBX
sub _check_dialect {
    my ($twig, $node) = @_;
    my $type = $node->att('dialect') || 'unknown';
    my $expected = 'TBX-Min';
    if($type ne $expected){
        croak "Input TBX is $type (should be '$expected')";
    }
    return 1;
}

# most of the twig handlers store state on the XML::Twig object.
# A bit kludgy, but it works.

sub _headerAtt {
    my ($twig, $node) = @_;
    $twig->{tbx_min_att}->{_decamel($node->name)} = $node->text;
    return 1;
}

sub _directionality {
    my ($twig, $node) = @_;
    _validate_dir($node->text);
    $twig->{tbx_min_att}->{directionality} = $node->text;
    return 1;
}

sub _date_created {
    my ($twig, $node) = @_;
    $twig->{tbx_min_att}->{date_created} =
        _parse_datetime($node->text);
    return;
}

# turn camelCase into camel_case
sub _decamel {
    my ($camel) = @_;
    $camel =~ s/([A-Z])/_\l$1/g;
    return $camel;
}

sub _languages{
    my ($twig, $node) = @_;
    if(my $source = $node->att('source')){
        ${ $twig->{'tbx_min_att'} }{'source_lang'} = $source;
    }
    if(my $target = $node->att('target')){
        ${ $twig->{'tbx_min_att'} }{'target_lang'} = $target;
    }
    return 1;
}

# add a new concept entry to the list of those found in this file
sub _conceptStart {
    my ($twig, $node) = @_;
    my $concept = TBX::Min::Entry->new();
    if($node->att('id')){
        $concept->id($node->att('id'));
    }else{
        carp 'found entry missing id attribute';
    }
    push @{ $twig->{tbx_min_entries} }, $concept;
    return 1;
}

#just set the subject_field of the current concept
sub _subjectField {
    my ($twig, $node) = @_;
    $twig->{tbx_min_entries}->[-1]->
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

    $twig->{tbx_min_entries}->[-1]->add_lang_group($lang);
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

