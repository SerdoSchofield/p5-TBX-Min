# test the functionality of TBX::Min::LangGroup

use strict;
use warnings;
use Test::More;
plan tests => 8;
use Test::Deep;
use Test::NoWarnings;
use_ok('TBX::Min::LangGroup');
use TBX::Min::TermGroup;
use FindBin qw($Bin);
use Path::Tiny;

my $args = {
    code => 'en',
    term_groups => [
        TBX::Min::TermGroup->new({term => 'foo'}),
        TBX::Min::TermGroup->new({term => 'bar'}),
    ],
};

#test constructor without arguments
my $lang_grp = TBX::Min::LangGroup->new;
isa_ok($lang_grp, 'TBX::Min::LangGroup');

ok(!$lang_grp->code, 'language not defined by default');

#test constructor with arguments
$lang_grp = TBX::Min::LangGroup->new($args);
is($lang_grp->code, $args->{code}, 'correct language code from constructor');
cmp_deeply($lang_grp->term_groups, $args->{term_groups},
    'correct term groups from constructor');

#test setters
$lang_grp = TBX::Min::LangGroup->new();

$lang_grp->code($args->{code});
is($lang_grp->code, $args->{code}, 'code correctly set');

$lang_grp->add_term_group($args->{term_groups}->[0]);
cmp_deeply($lang_grp->term_groups->[0], $args->{term_groups}->[0],
    'add_term_group works correctly');
