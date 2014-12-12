package Library::CallNumber::LC;

use warnings;
use strict;
use Math::BigInt;

=head1 NAME

Library::CallNumber::LC - Deal with Library-of-Congress call numbers

=head1 VERSION

Version 0.23;

=cut

our $VERSION = '0.23';


=head1 SYNOPSIS

Utility functions to deal with Library of Congress Call Numbers

    use Library::CallNumber::LC;
    my $a = Library::CallNumber::LC->new('A 123.4 .c11');
    print $a->normalize; # normalizes for string comparisons.
    # gives 'A01234 C11'
    print $a->start_of_range; # same as "normalize"
    my $b = Library::CallNumber::LC->new('B11 .c13 .d11');
    print $b->normalize;
    # gives 'B0011 C13 D11'
    my @range = ($a->start_of_range, $b->end_of_range);
    # end of range is 'B0011 C13 D11~'
    
    # Get components suitable for printing (e.g., number and decimal joined, leading dot on first cutter)
    @comps = Library::CallNumber::LC->new('A 123.4 .c11')->components()
    
    # Same thing, but return empty strings for missing components (e.g., the cutters)
    @comps = Library::CallNumber::LC->new('A 123.4 .c11')->components('true');

=head1 ABSTRACT

Library::CallNumber::LC is mostly designed to do call number normalization, with the following goals:

=over 4

=item * The normalized call numbers are comparable with each other, for proper sorting

=item * The normalized call number is a short as possible, so left-anchored wildcard searches are possible (e.g., searching on "A11*" should give you all the A11 call numbers)

=item * A range defined by start_of_range and end_of_range should be correct, assuming that the string given for the end of the range is, in fact, a left prefix.

=back

That last point needs some explanation. The idea is that if someone gives a range of, say, A-AZ, what they really mean is A - AZ9999.99. The end_of_range method generates a key which lies immediately beyond the last possible key for a given starting point. There is no attempt to make end_of_range normalization correspond to anything in real life.

=cut

# Set up the prefix mapping for longints 
my %intmap; 
my $i = 0;
foreach my $prefix (qw(a aa ab abc ac ae ag ah ai al am an anl ao ap aq arx as at aug aw awo ay az b bc bd bf bg bh bj bl bm bn bp bq br bs bt bu bv bx c cb cc cd ce cg cis cj cmh cmm cn cr cs ct cz d da daa daw db dc dd de df dff dg dh dj djk dk dkj dl doc dp dq dr ds dt dth du dx e ea eb ec ed ee ek ep epa ex f fb fc fem fg fj fnd fp fsd ft ful g ga gb gc gda ge gf gh gn gr gs gt gv h ha hb hc hcg hd he hf hfs hg hh hhg hj hjc hm hmk hn hq hs ht hv hx i ia ib iid ill ilm in ioe ip j ja jan jb jc jf jg jh jhe jj jk jkc jl jln jn jq js jv jx jz k kb kbm kbp kbq kbr kbu kc kd kdc kde kdg kdk kds kdz ke kea keb kem ken keo keq kes kf kfa kfc kfd kff kfg kfh kfi kfk kfl kfm kfn kfo kfp kfr kfs kft kfu kfv kfw kfx kfz kg kga kgb kgc kgd kge kgf kgg kgh kgj kgk kgl kgn kgq kgs kgt kgv kgx kh kha khc khd khf khh khk khp khq khu khw kit kj kja kjc kje kjg kjj kjk kjm kjn kjp kjq kjr kjs kjt kjv kjw kk kka kkb kkc kke kkf kkg kkh kki kkj kkm kkn kkp kkq kkr kks kkt kkv kkw kkx kky kkz kl kla klb kld kle klf klg klh klm kln klp klr kls klt klv klw km kmc kme kmf kmh kmj kmk kml kmm kmn kmo kmp kmq kmt kmu kmv kmx kn knc knd kne knf kng knh knk knl knm knn knp knq knr kns knt knu knw knx kny kp kpa kpc kpe kpf kpg kph kpj kpk kpl kpm kpp kps kpt kpv kpw kq kqc kqe kqg kqj kqk kqp kqw krb krc krg krm krn krp krr krs kru krv krx ks ksa ksc ksh ksj ksk ksl ksp kss kst ksv ksw ksx ksy kta ktd ktg ktj ktk ktl ktq ktr ktt ktu ktv ktw ktx kty ktz ku kuc kuq kvc kvf kvm kvn kvp kvq kvr kvs kvw kwc kwg kwh kwl kwp kwr kww kwx kz kza kzd l la law lb lc ld le lf lg lh lj ll ln lrm lt lv m may mb mc me mf mh mkl ml mpc mr ms mt my n na nat nax nb nc nd nda nds ne ner new ng nh nk nl nmb nn no nt nv nx ok onc p pa pb pc pcr pd pe pf pg ph phd pj pjc pk pl pm pn pnb pp pq pr ps pt pz q qa qb qc qd qe qh qk ql qm qp qr qry qu qv r ra rb rbw rc rcc rd re ref res rf rg rh rj rk rl rm rn rp rs rt rv rx rz s sb sd see sf sfk sgv sh sk sn sql sw t ta tc td tdd te tf tg tgg th tj tk tl tn tnj to tp tr ts tt tx tz u ua ub uc ud ue uf ug uh un use v va vb vc vd ve vf vg vk vla vm w wq x xp xx y yh yl yy z za zhn zz zzz)) {
  $intmap{$prefix} = $i;
  $i++;
}

# Regexp constants to deal with matching LC and variants

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
        (\d+[stndrh]*)? # optional extra numbering including suffixes (1st, 2nd, etc.)
        \s*
        (?:               # optional cutter
          (\.)? \s*     # optional decimal
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

# Class variables for top/bottom sort chars
my $Topper = ' '; # must sort before 'A'
my $Bottomer = '~'; # must sort after 'Z' and '9'


=head1 CONSTRUCTORS

=head2 new([call_number_text, [topper_character, [bottomer_character]]]) -- create a new object, optionally passing in the initial string, a "topper", and a "bottomer" (explained below)

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $lc = shift || '';
  my $topper = shift;
  $topper = $Topper if !defined($topper); # ZERO is false but might be a reasonable value, so we need this more specific check
  my $bottomer = shift || $Bottomer;
  my $self = {
    callno => $lc,
    topper => $topper,
    bottomer => $bottomer
  };
  bless $self, $class;
  return $self;
}


=head1 BASIC ACCESSORS

=head2 call_number([call_number_text])

The text of the call number we are dealing with.

=cut

sub call_number {
  my $self = shift;
  if (@_) { $self->{callno} = uc(shift) }
  return $self->{callno};
}

=head2 topper([character])

Specify which character occupies the 'always-sort-to-the-top' slots in the sort keys.  Defaults to the SPACE character, but can reasonably be anything with an ASCII value lower than 48 (i.e. the 'zero' character, '0').  This can function as either a class or instance method depending on need.

=cut

sub topper {
  my $self = shift;
  my $topper = shift;
  if (ref $self) {
    $self->{topper} = $topper if $topper; # just myself
    return $self->{topper};
  } else {
    $Topper = $topper if $topper; # whole class
    return $Topper;
  }
}

=head2 bottomer([character])

Specify which character occupies the 'always-sort-to-the-bottom' slots in the sort keys.  Defaults to the TILDE character, but can reasonably be anything with an ASCII value higher than 90 (i.e. 'Z').  This can function as either a class or instance method depending on need.

=cut

sub bottomer {
  my $self = shift;
  my $bottomer = shift;
  if (ref $self) {
    $self->{bottomer} = $bottomer if $bottomer; # just myself
    return $self->{bottomer};
  } else {
    $Bottomer = $bottomer if $bottomer; # whole class
    return $Bottomer;
  }
}

=head1 OTHER METHODS

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


  my ($alpha, $num, $dec, $othernum, $c1dec, $c1alpha, $c1num, $c2alpha, $c2num, $c3alpha, $c3num, $extra) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);

  #combine stuff if need be
  
  if ($dec) {
    $num .= '.' . $dec;
  }
  
  no warnings;
  my $c1 = join('', $c1alpha, $c1num);
  my $c2 = join('', $c2alpha, $c2num);
  my $c3 = join('', $c3alpha, $c3num);
  
  use warnings;

  $c1 = '.' . $c1 if $c1dec;

  my @return;
  foreach my $comp ($alpha, $num, $othernum, $c1, $c2, $c3, $extra) {
    $comp = '' unless (defined $comp);
    next unless ($comp =~ /\S/ or $returnAll);
    $comp =~ m/^\s*(.*?)\s*$/;
    $comp = $1;
    push @return, $comp;
  }
  return @return;
}

=head2 _normalize(call_number_text)

Base function to perform normalization.

=cut

sub _normalize {
  my $self = shift;
  my $lc = uc(shift);

  my $topper = $self->topper;

#  return undef if ($lc =~ $weird);
  return undef unless ($lc =~ $lcregex);
  
  my ($alpha, $num, $dec, $othernum, $c1dec, $c1alpha, $c1num, $c2alpha, $c2num, $c3alpha, $c3num, $extra) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);

  no warnings;
  my $class = $alpha;
  $class .= sprintf('%04s', $num) if $num;
  $class .= $dec if $dec;
  my $c1 = $c1alpha.$c1num;
  my $c2 = $c2alpha.$c2num;
  my $c3 = $c3alpha.$c3num;

  # normalize extra (most commonly years/numbering, benefits from padding)
  # this could be reduced to a four digit pad, as very, very few numbers
  # reach 10000, but we'll be conservative here (for now)
  $extra =~ s/^\s+//g;
  $extra =~ s/\.\s+/./g;
  $extra =~ s/(\d)\s*-\s*(\d)/$1-$2/g;
  $extra =~ s/(\d+)/sprintf("%05s", $1)/ge;
  $extra = $topper . $extra if ($extra ne ''); # give the extra less 'weight' for falling down the list
  
  # pad out othernum (again, conservatively)
  $othernum =~ s/(\d+)/sprintf("%05s", $1)/ge;

  return join($topper, grep {/\S/} ($class, $othernum, $c1, $c2, $c3, $extra));
}

=head2 normalize([call_number_text])

Normalize the stored or passed call number as a sortable string

=cut

sub normalize {
  my $self = shift;
  my $lc = shift;
  $lc = $lc? uc($lc) : $self->{callno};
  return $self->_normalize($lc)
}

=head2 start_of_range([call_number_text])

Alias for normalize

=cut

sub start_of_range {
  my $self = shift;
  return $self->normalize(@_);
}

=head2 end_of_range([call_number_text])

Downshift an lc number so it represents the end of a range

=cut

sub end_of_range {
  my $self = shift;
  my $lc = shift;
  $lc = $lc? uc($lc) : $self->{callno};
  my $bottomer = $self->bottomer;
  return $self->_normalize($lc) . $bottomer;
}

=head2 toLongInt(call_number_text, num_digits)

Attempt to turn a call number into an integer value. Possibly useful for fast range checks, although obviously not perfectly accurate. Optional argument I<$num_digits> can be used to control the number of digits used, and therefore the precision of the results.

=cut

my $minval = new Math::BigInt('0'); # set to zero until this code matures
my $minvalstring = $minval->bstr;

# this is a work in progress, with room for improvement in both exception
# logic and overall economy of bits
sub toLongInt {
  my $self = shift;
  my $lc = shift;
  my $num_digits = shift || 19; # 19 is a max-fit for 64-bits within our scope

  my $topper = $self->topper;
  my $bottomer = $self->bottomer;

  #print "$lc\n";
  my $topper_ord = ord($topper);
  my $long = $self->normalize($lc);

  return $minvalstring unless ($long);

  my ($alpha, $num, $rest);
  if ($long =~ /^([A-Z]+)(\d{4})(.*)$/) { # we have a 'full' call number
    ($alpha, $num, $rest) = (lc($1), $2, $3);
  } elsif ($long =~ /^([A-Z]+)(.*)$/) { # numberless class; generally invalid, but let it slide for now 
    ($alpha, $rest) = (lc($1), $2);
    if ($rest =~ /^$bottomer/) { # bottomed-out class
        $num = '9999';
    } else {
        $num = '0000';
    }
  }
  my $class_int_string = '';
  if (defined($intmap{$alpha})) { 
    $class_int_string .= $intmap{$alpha} . $num; 
  } else { 
    warn "Unknown prefix '$alpha'\n";     
    return $minvalstring; 
  }
  my $rest_int_string = '';
  my $bottomout;
  foreach my $char (split('', $rest)) { 
    if ($char eq $bottomer) {
      $bottomout = 1; 
      last;
    }
    $rest_int_string .= sprintf('%02d', ord($char) - $topper_ord); 
  } 

  $rest_int_string = substr($rest_int_string, 0, $num_digits - 7); # Reserve first seven digits for $alpha and $num
  if ($bottomout) {
    $rest_int_string .= '9' x (($num_digits - 7) - length($rest_int_string)); # pad it if need be
  } else {
    $rest_int_string .= '0' x (($num_digits - 7) - length($rest_int_string)); # pad it if need be
  }

#   print "  $long => ", join('', @rv), "\n";
   my $longint = Math::BigInt->new($class_int_string . $rest_int_string);
   $longint->badd($minval);
#   warn "\n\n".$self->_normalize($lc)." = ".$longint->bstr." ( $class_int_string + $rest_int_string) \n\n";
   return $longint->bstr;
   
}



=head1 AUTHOR

Current Maintainer: Dan Wells, C<< <dbw2 at calvin.edu> >>
Original Author: Bill Dueber, C<< <dueberb at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://code.google.com/p/library-callnumber-lc/issues/list>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Library::CallNumber::LC


You can also look for information at the Google Code page:

  http://code.google.com/p/library-callnumber-lc/


=head1 COPYRIGHT & LICENSE

Copyright 2009 Bill Dueber, all rights reserved.
Copyright 2011 Dan Wells, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself and also under the new BSD license
as described at http://www.opensource.org/licenses/bsd-license.php


=cut

1; # End of Library::CallNumber::LC
