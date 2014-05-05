#!/usr/bin/perl
#
# for context, see http://bugs.koha.org/cgi-bin/bugzilla/show_bug.cgi?id=2691

use strict;
use warnings;

use Test::More tests => 26;

use Library::CallNumber::LC;

my $lccns = {
    'HE8700.7 .P6T44 1983' => [qw(HE 8700.7 .P6 T44 1983)],
    'BS2545.E8 H39 1996'   => [qw(BS 2545 .E8 H39 1996)],
    'NX512.S85 A4 2006'    => [qw(NX 512 .S85 A4 2006)],
    'J 295.435 K56'        => [qw(J 295.435 K56)],
};

foreach my $lccn (sort keys %$lccns) {
    my @expected = @{$lccns->{$lccn}};
    my @parts = Library::CallNumber::LC->new($lccn)->components;
    ok($lccn, "lccn: $lccn (" . join(" | ", @parts) . ')');
    is(scalar(@parts), scalar(@expected), "$lccn: Correctly produced " . scalar(@expected) . " parts");
    my $i = 0;
    foreach my $unit (@expected) {
      is($parts[$i], $unit, "$lccn: Correctly matched $unit at position $i");
      $i++;
    }
}

