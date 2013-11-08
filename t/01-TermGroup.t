#test the functionality of TBX::Min::TermGroup

use strict;
use warnings;
use Test::More;
plan tests => 18;
use Test::NoWarnings;
use_ok('TBX::Min::TermGroup');
use FindBin qw($Bin);
use Path::Tiny;

my $args = {
    term => 'foo1',
    part_of_speech => 'foo2',
    note => 'foo3',
    customer => 'foo4',
    status => 'foo5',
};


#test constructor without arguments
my $term_grp = TBX::Min::TermGroup->new();
isa_ok($term_grp, 'TBX::Min::TermGroup');

ok(!$term_grp->term, 'term not defined by default');
ok(!$term_grp->part_of_speech, 'part_of_speech not defined by default');
ok(!$term_grp->note, 'note not defined by default');
ok(!$term_grp->customer, 'customer not defined by default');
ok(!$term_grp->status, 'status not defined by default');

#test constructor with arguments
$term_grp = TBX::Min::TermGroup->new($args);
is($term_grp->term, $args->{term}, 'correct term from constructor');
is($term_grp->part_of_speech, $args->{part_of_speech},
    'correct part_of_speech from constructor');
is($term_grp->note, $args->{note}, 'correct note from constructor');
is($term_grp->customer, $args->{customer}, 'correct customer from constructor');
is($term_grp->status, $args->{status}, 'correct status from constructor');

#test setters
$term_grp = TBX::Min::TermGroup->new();

$term_grp->term($args->{term});
is($term_grp->term, $args->{term}, 'term correctly set');

$term_grp->part_of_speech($args->{part_of_speech});
is($term_grp->part_of_speech, $args->{part_of_speech}, 'part_of_speech correctly set');

$term_grp->note($args->{note});
is($term_grp->note, $args->{note}, 'note correctly set');

$term_grp->customer($args->{customer});
is($term_grp->customer, $args->{customer}, 'customer correctly set');

$term_grp->status($args->{status});
is($term_grp->status, $args->{status}, 'status correctly set');
