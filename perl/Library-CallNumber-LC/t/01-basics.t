#!perl -T

use Library::CallNumber::LC;
use Test::More qw(no_plan);
use Math::BigInt;

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

is($a->normalizeFullLength('B11'), 'B  001100 000 000 000', "Full Length");
is($a->normalizeFullLength('B'),   'B  000000 000 000 000', "Full Length");


my @test = (
 "a 0",
 "a 1 1923",
 "a 8 f166",
 "a19 f96",
 "a19f99g15",
 "a242 83 i65",
 "a610 h18",
 "a610.5 c75 m5 1910",
 "a610.8 e8f 0",
 "a610.9 c27pr 0",
 "a610.9 c38tr 0",
 "a610.9 f16",
 "a610.9 g38n 0",
 "a610.9 m96",
 "a612.601 c8",
 "a614.2 f36",
 "a614.4972 c12 es 0",
 "a615.1 n84",
 "a615.11 f23",
 "a615.3 s68pl 0",
 "a615.7 o5l 0",
 "a618.2 l58n 0",
 "a618.2 r7g 0",
 "a820.3 b 0",
 "aa 0",
 "aa39",
 "aa102 ottawapt 1-final 0",
 "ab 0",
 "abc 0",
 "ac 1 a52",
 "ac 1 a671 2000",
 "ac 1 a926 r 0",
 "ac 1 b26",
 "ac 1 c2",
 "ac 1 c212",
 "ac 1 e45",
 "ac 1 f142",
 "ac 1 g78",
 "zzz19f99g15",
 "zzz 1945 f99g15 d11 1990",
 
);

my @testints;
foreach my $t (@test) {
  my $l = $a->toLongInt($t);
  next unless ($l);
  push @testints, Math::BigInt->new($l);
}
for ($j = 0; $j < scalar(@test) -1; $j++) {
  my $n1 = $a->normalize($test[$j]);
  my $n2 = $a->normalize($test[$j+1]);
  my $l1 = $a->normalizeFullLength($test[$j]);
  my $l2 = $a->normalizeFullLength($test[$j+1]);
  my $i1 = new Math::BigInt $a->toLongInt($test[$j]);
  my $i2 = new Math::BigInt $a->toLongInt($test[$j+1]);
  
  next unless ($n1 and $n2); # skip the invalids
   
#  ok($testints[$j] < $testints[$j+1], $a->normalizeFullLength($test[$j]) . " < " . $a->normalizeFullLength($test[$j+1]));
  ok($n1 le $n2, $test[$j] . ' < ' . $test[$j+1] . ' (normalize)');
  ok($l1 le $l2, $test[$j] . ' < ' . $test[$j+1] . ' (normalizeFullLength)');
  ok($i1->bcmp($i2) < 0, $test[$j] . ' < ' . $test[$j+1] . " (toLongInt $i1 vs $i2)");
}
