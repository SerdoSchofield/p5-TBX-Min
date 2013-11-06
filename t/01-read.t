#basic test file

use strict;
use warnings;
use Test::More;
plan tests => 22;
use Test::NoWarnings;
use TBX::Min;
use FindBin qw($Bin);
use Path::Tiny;
use Data::Dumper;

my $corpus_dir = path($Bin, 'corpus');
my $basic_path = path($corpus_dir, 'basic.tbx');
test_read("$basic_path");
# my $basic_txt = $basic_path->slurp;
# test_read(\$basic_txt);


sub test_read {
    my ($input) = @_;
    my $min = TBX::Min->new(file => $input);

    isa_ok($min, 'TBX::Min');
    test_header($min);
    test_body($min);
}

sub test_header {
    my ($min) = @_;
    is($min->title, 'TBX sample', 'correct title');
    is($min->origin, 'Klaus-Dirk Schmidt', 'correct origin');
    is($min->license, 'CC BY license can be freely copied and modified',
        'correct license');
    is($min->subject_field, 'biology', 'correct subject field');
    is($min->directionality, 'bidirectional', 'correct directionality');
    is($min->source_lang, 'de', 'correct source language');
    is($min->target_lang, 'en', 'correct target language');
}

sub test_body {
    my ($min) = @_;
    my $concepts = $min->concepts;
    is(scalar @$concepts, 3, 'found three concepts');

    my $concept = $concepts->[0];
    isa_ok($concept, 'TBX::Min::Concept');
    is($concept->id, 'C002', 'correct concept ID');
    my $languages = $concept->languages;
    is(scalar @$languages, 2, 'found two languages');

    my $language = $languages->[1];
    isa_ok($language, 'TBX::Min::Concept::Language');
    is($language->code, 'en', 'language is English');
    my $terms = $language->terms;
    is(scalar @$terms, 2, 'found two terms');

    my $term = $terms->[1];
    isa_ok($term, 'TBX::Min::Concept::Language::Term');
    is($term->text, 'hound', 'correct term text');
    is($term->part_of_speech, 'noun', 'correct part of speech');
    is($term->status, 'deprecated', 'correct status');
    is($term->customer, 'SAP', 'correct customer');
    is($term->note, 'however bloodhound is used rather than blooddog',
        'correct note');
}

