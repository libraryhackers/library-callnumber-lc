#!perl -T

use Library::CallNumber::LC;
use Test::More qw(no_plan);
use Math::BigInt;

my $a = Library::CallNumber::LC->new('A');
is($a->normalize, 'A', "Basic normalization");
is($a->normalize, $a->start_of_range, "Equvalent functions");
is($a->end_of_range, 'A~', "End of range");

my $LC = Library::CallNumber::LC->new();
is($LC->normalize('A11.1'), 'A00111', "Basic normalization");
is($LC->end_of_range('A11.1'), 'A00111~', "End of range");

is($a->normalize('B11'), 'B0011', "Passed in arg");

is($a->normalize('A 123.4 .c11'), 'A01234 C11', "Cutter");
is($a->normalize('B11 A543 B6'), 'B0011 A543 B6', "Two cutters");
is($a->start_of_range('B11 .c13 .d11'), 'B0011 C13 D11', "Two cutters start");
is($a->end_of_range('B11 .c13 .d11'), 'B0011 C13 D11~', "Two cutters end");


my @test = (
 "a 0",
 "a 1 1923",
 "a 8 f166",
 "a19 f96",
 "a19f99g15",
 "a19 .f99 g15 1997",
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
 "ac 1 a6713 2000",
 "ac 1 a926 r 0",
 "ac 1 b26",
 "ac 1 c2",
 "ac 1 c212",
 "ac 1 e45",
 "ac 1 f142",
 "ac 1 g78",
 "tk5105.87 .g57 1993",
 "tk5105.875 .i57 c92 2005",
 "tk5105.888 .s43 1997",
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
  my $i1 = new Math::BigInt $a->toLongInt($test[$j]);
  my $i2 = new Math::BigInt $a->toLongInt($test[$j+1]);
  
  next unless ($n1 and $n2); # skip the invalids
   
  ok($n1 lt $n2, $test[$j] . ' < ' . $test[$j+1] . ' (normalize)');
  # must allow "or equal" due to lack of precision
  ok($i1->bcmp($i2) <= 0, $test[$j] . ' < ' . $test[$j+1] . " (toLongInt $i1 vs $i2)");
}
