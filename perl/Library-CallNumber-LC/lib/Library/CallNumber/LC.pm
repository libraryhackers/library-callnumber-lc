package Library::CallNumber::LC;

use warnings;
use strict;

=head1 NAME

Library::CallNumber::LC - Deal with Library-of-congress call numbers

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.10';


=head1 SYNOPSIS

Utility functions to deal with Library of Congress Call Numbers

    use Library::CallNumber::LC;
    my $a = Library::CallNumber::LC->new('A 123.4 .c11');
    print $a->normalize; # normalizes for string comparisons.
    # gives 'A  012340C110'
    print $a->start_of_range; # same as "normalize"
    my $b = Library::CallNumber::LC->new('B11 .c13 .d11');
    print $b->normalize;
    # gives 'B  001100C130D110'
    my @range = ($a->start_of_range, $b->end_of_range);
    # end of range is 'B  001100C130D119~999'
    
    # Get components suitable for printing (e.g., number and decimal joined, leading dot on first cutter)
    @comps = Library::CallNumber::LC->new('A 123.4 .c11')->components()
    
    # Same thing, but return empty strings for missing components (e.g., the cutters)
    @comps = Library::CallNumber::LC->new('A 123.4 .c11')->components('true');

=head1 ABSTRACT

Library::CallNumber::LC is mostly designed to do call number normalization, with the following goals:

=over 4

=item * The normalized call numbers are comparable with each other, for proper sorting

=item * The normalized call number is a short as possible, so left-anchored wildcard searches are possible
(e.g., searching on "A11*" should give you all the A11 call numbers)

=item * A range defined by start_of_range and end_of_range should be correct, assuming that the string given for 
the end of the range is, in fact, a left prefix.

=back

That last point needs some explanation. The idea is that if someone gives a range of, say, A-AZ, what
they really mean is A - AZ9999.99. The end_of_range method pads the given call number out to three
cutters if need be. There is no attempt to make end_of_range normalization correspond to anything in real life.

=head1 CONSTANTS

Regexp constants to deal with matching LC and variants

=cut

# Set up the mapping for longints 
my %intmap; 
my $i = 0;
# First the characters my $i = 0; 
foreach my $char (' ', 'A'..'Z', '~') { 
  $intmap{$char} = sprintf('%02d', $i); 
  $i++; 
} 
 
# ...and the digits 
foreach my $char (0..9) { 
  $intmap{$char} = $char; 
}

# And now the prefixes
$i = 0;
foreach my $prefix qw(a aa ab abc ac ae ag ah ai al am an anl ao ap aq arx as at aug aw awo ay az b bc bd bf bg bh bj bl bm bn bp bq br bs bt bu bv bx c cb cc cd ce cg cis cj cmh cmm cn cr cs ct cz d da daa daw db dc dd de df dff dg dh dj djk dk dkj dl doc dp dq dr ds dt dth du dx e ea eb ec ed ee ek ep epa ex f fb fc fem fg fj fnd fp fsd ft ful g ga gb gc gda ge gf gh gn gr gs gt gv h ha hb hc hcg hd he hf hfs hg hh hhg hj hjc hm hmk hn hq hs ht hv hx i ia ib iid ill ilm in ioe ip j ja jan jb jc jf jg jh jhe jj jk jkc jl jln jn jq js jv jx jz k kb kbm kbp kbq kbr kbu kc kd kdc kde kdg kdk kds kdz ke kea keb kem ken keo keq kes kf kfa kfc kfd kff kfg kfh kfi kfk kfl kfm kfn kfo kfp kfr kfs kft kfu kfv kfw kfx kfz kg kga kgb kgc kgd kge kgf kgg kgh kgj kgk kgl kgn kgq kgs kgt kgv kgx kh kha khc khd khf khh khk khp khq khu khw kit kj kja kjc kje kjg kjj kjk kjm kjn kjp kjq kjr kjs kjt kjv kjw kk kka kkb kkc kke kkf kkg kkh kki kkj kkm kkn kkp kkq kkr kks kkt kkv kkw kkx kky kkz kl kla klb kld kle klf klg klh klm kln klp klr kls klt klv klw km kmc kme kmf kmh kmj kmk kml kmm kmn kmo kmp kmq kmt kmu kmv kmx kn knc knd kne knf kng knh knk knl knm knn knp knq knr kns knt knu knw knx kny kp kpa kpc kpe kpf kpg kph kpj kpk kpl kpm kpp kps kpt kpv kpw kq kqc kqe kqg kqj kqk kqp kqw krb krc krg krm krn krp krr krs kru krv krx ks ksa ksc ksh ksj ksk ksl ksp kss kst ksv ksw ksx ksy kta ktd ktg ktj ktk ktl ktq ktr ktt ktu ktv ktw ktx kty ktz ku kuc kuq kvc kvf kvm kvn kvp kvq kvr kvs kvw kwc kwg kwh kwl kwp kwr kww kwx kz kza kzd l la law lb lc ld le lf lg lh lj ll ln lrm lt lv m may mb mc me mf mh mkl ml mpc mr ms mt my n na nat nax nb nc nd nda nds ne ner new ng nh nk nl nmb nn no nt nv nx ok onc p pa pb pc pcr pd pe pf pg ph phd pj pjc pk pl pm pn pnb pp pq pr ps pt pz q qa qb qc qd qe qh qk ql qm qp qr qry qu qv r ra rb rbw rc rcc rd re ref res rf rg rh rj rk rl rm rn rp rs rt rv rx rz s sb sd see sf sfk sgv sh sk sn sql sw t ta tc td tdd te tf tg tgg th tj tk tl tn tnj to tp tr ts tt tx tz u ua ub uc ud ue uf ug uh un use v va vb vc vd ve vf vg vk vla vm w wq x xp xx y yh yl yy z za zhn zz zzz ) {
  $intmap{$prefix} = sprintf("%02d", $i);
  $i++;
}

my $lcregex = qr/^
        \s*
        (?:VIDEO-D)? # for video stuff
        (?:DVD-ROM)? # DVDs, obviously
        (?:CD-ROM)?  # CDs
        (?:TAPE-C)?  # Tapes
        \s*
        ([A-Z]{1,3})  # alpha
        \s*
        (?:         # optional numbers with optional decimal point
          (\d+)
          (?:\s*?\.\s*?(\d+))? 
        )?
        \s*
        (?:               # optional cutter
          \.? \s*     
          ([A-Z])      # cutter letter
          \s*
          (\d+ | \Z)?        # cutter numbers
        )?
        \s*
        (?:               # optional cutter
          \.? \s*     
          ([A-Z])      # cutter letter
          \s*
          (\d+ | \Z)?        # cutter numbers
        )?
        \s*
        (?:               # optional cutter
          \.? \s*     
          ([A-Z])      # cutter letter
          \s*
          (\d+ | \Z)?        # cutter numbers
        )?
        (\s+.+?)?        # everthing else
        \s*$
  /x;



my $weird = qr/
  ^
  \s*[A-Z]+\s*\d+\.\d+\.\d+
/x;

# Change to make more readable/ more compact
my $join = '';
my $topspace = ' '; # must sort before 'A'
my $bottomspace = '~'; # must sort after 'Z' and '9'
my $topdigit = '0';    # should be zero
my $bottomdigit = '9'; # should be 9


=head1 FUNCTIONS

=head2 new
=head2 new($lc) -- create a new object, optionally passing in the inital string

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $lc = shift || '';
  my $self = {
    callno => uc($lc),
  };
  bless $self, $class;
  return $self;
}


=head2 components(boolean returnAll = false)

  @comps = Library::CallNumber::LC->new('A 123.4 .c11')->components($returnAll)

Returns an array of the individual components of the call number (or undef if it doesn't look like a call number).
Components are:

=over 4

=item * alpha

=item * number (numeric.decimal)

=item * cutter1 

=item * cutter2 

=item * cutter3

=item * "extra" (anything after the cutters)

=back

The optional argument <I returnAll> (false by default) determines whether or not empty components (e.g., 
extra cutters) get a slot in the returned list. 

=cut

sub components {
  my $self = shift;
  my $returnAll = shift;
  my $lc = $self->{callno};

  return undef if ($lc =~ $weird);
  return undef unless ($lc =~ $lcregex);


  my ($alpha, $num, $dec, $c1alpha, $c1num, $c2alpha, $c2num,$c3alpha, $c3num, $extra) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);

  #combine stuff if need be
  
  if ($dec) {
    $num .= '.' . $dec;
  }
  
  no warnings;
  my $c1 = join('', $c1alpha, $c1num);
  my $c2 = join('', $c2alpha, $c2num);
  my $c3 = join('', $c3alpha, $c3num);
  
  $c1 = '.' . $c1 if ($c1 =~ /\S/);
  use warnings;
  
  my @return;
  foreach my $comp ($alpha, $num, $c1, $c2, $c3, $extra) {
    $comp = '' unless (defined $comp);
    next unless ($comp =~ /\S/ or $returnAll);
    $comp =~ m/^\s*(.*?)\s*$/;
    $comp = $1;
    push @return, $comp;
  }
  return @return;
}

=head2 _normalize(string $lc, boolean $bottom)

Utility function to perform normalization to both start and end
of range, as well as output formats

=cut

sub _normalize {
  my $self = shift;
  my $lc = uc(shift);
  my $bottomout = shift;
  my $fulllength = shift;
  
  return undef if ($lc =~ $weird);
  return undef unless ($lc =~ $lcregex);
  
  my @origs = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
  my ($alpha, $num, $dec, $c1alpha, $c1num, $c2alpha, $c2num,$c3alpha, $c3num, $extra) = @origs;

  # We have some records that aren't LoC Call Numbers, but start like them, only with three digits in the decimal. Ditch them
  
  return undef if ($dec and (length($dec) > 2));
  
  # If we've got an extra, but *nothing else* except for the alpha, it's probably too weird to deal with
  no warnings;
  if ($alpha and not ($num or $dec or $c1alpha or $c1num or $c2alpha or $c2num or$c3alpha or $c3num)) 
  {
    if ($extra) 
    {
      return undef;
    }
    if ($bottomout) 
    {
      return $alpha . $bottomspace x (3 - length($alpha));
    }
    return $alpha unless ($fulllength)
  }

  # Normalize each part and push them onto a stack
  
  my $enorm = $extra;
  $enorm =~ s/[^A-Z0-9]//g;
  $num = sprintf('%04d', $num);
  
  
  my @topnorm =($alpha . $topspace x (3 - length($alpha)), 
             $num . $topdigit x (4 - length($num)),
             $dec . $topdigit x (2 - length($dec)),
             $c1alpha? $c1alpha : $topspace,
             $c1num . $topdigit x (3 - length($c1num)),
             $c2alpha? $c2alpha : $topspace,
             $c2num . $topdigit x (3 - length($c2num)),
             $c3alpha? $c3alpha : $topspace,
             $c3num . $topdigit x (3 - length($c3num)),         
             ' ' . $enorm,
            ); 
  return join($join, @topnorm) if ($fulllength and not $bottomout);

  my @bottomnorm =($alpha . $bottomspace x (3 - length($alpha)), 
             $num . $bottomdigit x (4 - length($num)),
             $dec . $bottomdigit x (2 - length($dec)),
             $c1alpha? $c1alpha : $bottomspace,
             $c1num . $bottomdigit x (3 - length($c1num)),
             $c2alpha? $c2alpha : $bottomspace,
             $c2num . $bottomdigit x (3 - length($c2num)),
             $c3alpha? $c3alpha : $bottomspace,
             $c3num . $bottomdigit x (3 - length($c3num)),         
             ' ' . $enorm,
            ); 

  
  if ($extra) 
  {
    return join($join, @topnorm);
  }
  
  
  pop @topnorm; pop @bottomnorm; # ditch the extra
  
  # foreach my $i ($c3num, $c3alpha, $c2num, $c2alpha, $c1num, $c1alpha, $dec, $num) {
  for (my $i = 8; $i >= 1; $i--) 
  {
    my $end = pop @topnorm;
    
    if ($origs[$i]) 
    {
      if ($bottomout) 
      {
        $end = join($join, @bottomnorm[$i..$#bottomnorm]);
      }
      return join($join, @topnorm) . $join .  $end;
    }
  }
  use warnings;
}

=head2 normalize() -- normalize the callno in the current object as a sortable string
=head2 normalize($lc) -- normalize the passed callno as a sortable string

=cut

sub normalize {
  my $self = shift;
  my $lc = shift;
  $lc = $lc? uc($lc) : $self->{callno};
  return $self->_normalize($lc, 0)
}

=head2 normalizeFullLength($lc) 

Force normaliztion to return the full-length string (as opposed to the shortest possible string) for ease
in converting to an int.

=cut

sub normalizeFullLength {
  my $self = shift;
  my $lc = shift;
  $lc = $lc? uc($lc) : $self->{callno};
  my $long =  $self->_normalize($lc, 0, 1);
  unless ($long) {
    return undef;
  }
  $long =~ s/\s+$//;
  return $long;
}

=head2 start_of_range (alias for normalize)

=cut

sub start_of_range {
  my $self = shift;
  return $self->normalize(@_);
}

=head2 end_of_range($lc) -- downshift an lc number so it represents the end of a range

=cut

sub end_of_range {
  my $self = shift;
  my $lc = shift;
  $lc = $lc? uc($lc) : $self->{callno};
  return $self->_normalize($lc, 1);
}


=head2 partialToLongInt($lc)

Turn everything up to and including the secondp cutter into a long integer. Useful for fast range checks, although obviously
not perfectly accurate.

=cut

sub toLongInt {
  my $self = shift;
  my $lc = shift;
  $lc = $lc? uc($lc) : $self->{callno};
  #print "$lc\n";
  my $long = $self->normalizeFullLength($lc);
  return undef unless ($long);
  $long = substr($long, 0, 16); # Just up through first cutter AAA 999 99 A 999 A 999
  $long = $long . ' ' x (16 - length($long)); # pad it if need be
  $long =~ /^(...)(.*)$/;
  my ($prefix, $rest) = (lc($1), $2);
  $prefix =~ s/\s+$//;
  my @rv; 
  if (defined($intmap{$prefix})) { 
    push @rv, $intmap{$prefix}; 
  } else { 
    warn "Unknown prefix '$prefix'\n";     return undef; 
  }
  foreach my $char (split('', $rest)) { 
     push @rv, "$intmap{$char}"; 
   } 
#   print "  $long => ", join('', @rv), "\n";
   return join('', @rv);    
}



=head1 AUTHOR

Bill Dueber, C<< <dueberb at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-library-callnumber-lc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Library-CallNumber-LC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Library::CallNumber::LC


You can also look for information at the Google Code page:

  http://code.google.com/p/library-callnumber-lc/

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Bill Dueber, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as the new BSD licsense as descirbed at 
http://www.opensource.org/licenses/bsd-license.php


=cut

1; # End of Library::CallNumber::LC
