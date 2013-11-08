#test the basic functionality of TBX::Min

use strict;
use warnings;
use Test::More;
plan tests => 27;
use Test::NoWarnings;
use Test::Deep;
use_ok('TBX::Min');
use TBX::Min::ConceptEntry;
use FindBin qw($Bin);
use Path::Tiny;

my $args = {
    doc_lang => 'foo0',
    title => 'foo1',
    origin => 'foo2',
    license => 'foo3',
    directionality => 'foo5',
    source_lang => 'foo6',
    target_lang => 'foo7',
    concepts => [
        TBX::Min::ConceptEntry->new({id => 'foo'}),
        TBX::Min::ConceptEntry->new({id => 'bar'}),
    ],
};


#test constructor without arguments
my $min = TBX::Min->new();
isa_ok($min, 'TBX::Min');

ok(!$min->doc_lang, 'doc_lang not defined by default');
ok(!$min->title, 'title not defined by default');
ok(!$min->origin, 'origin not defined by default');
ok(!$min->license, 'license not defined by default');
ok(!$min->directionality, 'directionality not defined by default');
ok(!$min->source_lang, 'source_lang not defined by default');
ok(!$min->target_lang, 'target_lang not defined by default');
ok(!$min->concepts, 'concepts not defined by default');

#test constructor with arguments
$min = TBX::Min->new($args);
is($min->doc_lang, $args->{doc_lang}, 'correct doc_lang from constructor');
is($min->title, $args->{title}, 'correct title from constructor');
is($min->origin, $args->{origin}, 'correct origin from constructor');
is($min->license, $args->{license}, 'correct license from constructor');
is($min->directionality, $args->{directionality},
    'correct directionality from constructor');
is($min->source_lang, $args->{source_lang},
    'correct source_lang from constructor');
is($min->target_lang, $args->{target_lang},
    'correct target_lang from constructor');
cmp_deeply($min->concepts, $args->{concepts}, 'correct concepts from constructor');

#test setters
$min = TBX::Min->new();

$min->doc_lang($args->{doc_lang});
is($min->doc_lang, $args->{doc_lang}, 'doc_lang correctly set');

$min->title($args->{title});
is($min->title, $args->{title}, 'title correctly set');

$min->origin($args->{origin});
is($min->origin, $args->{origin}, 'origin correctly set');

$min->license($args->{license});
is($min->license, $args->{license}, 'license correctly set');

$min->directionality($args->{directionality});
is($min->directionality, $args->{directionality}, 'directionality correctly set');

$min->source_lang($args->{source_lang});
is($min->source_lang, $args->{source_lang}, 'source_lang correctly set');

$min->target_lang($args->{target_lang});
is($min->target_lang, $args->{target_lang}, 'target_lang correctly set');

$min->add_concept($args->{concepts}->[0]);
cmp_deeply($min->concepts->[0], $args->{concepts}->[0],
    'add_concepts works correctly');
