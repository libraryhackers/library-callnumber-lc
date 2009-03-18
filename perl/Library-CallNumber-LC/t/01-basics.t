#!perl -T

use Library::CallNumber::LC;
use Test::More qw(no_plan);

my $a = Library::CallNumber::LC->new('A');
is($a->normalize, 'A', "Basic normalization");
is($a->normalize, $a->start_of_range, "Equvalent functions");
is($a->end_of_range, 'A~~', "End of range");

$a = Library::CallNumber::LC->new('A11.1');
is($a->normalize, 'A  001110', "Basic normalization");
is($a->end_of_range, 'A  001119~999~999~999', "End of range");

is($a->normalize('B11'), 'B  0011', "Passed in arg");

is($a->normalize('A 123.4 .c11'), 'A  012340C110', "Cutter");
is($a->normalize('B11 .c13 .d11'), 'B  001100C130D110', "Two cutters start");
is($a->end_of_range('B11 .c13 .d11'), 'B  001100C130D119~999', "Two cutters end");
