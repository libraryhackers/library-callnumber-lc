package Library::CallNumber::LC;

use warnings;
use strict;

=head1 NAME

Library::CallNumber::LC - Deal with Library-of-congress call numbers

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Utility functions to deal with Library of Congress Call Numbers

    use Library::CallNumber::LC;
    my $a = Library::CallNumber::LC->new('A 123.4 .c11);
    print $a->normalize; # normalizes for string comparisons.
    # gives 'A  012340C110'
    print $a->start_of_range; # same as "normalize"
    my $b = Library::CallNumber::LC->new('B11 .c13 .d11');
    print $b->normalize;
    # gives 'B  001100C130D110'
    my @range = ($a->start_of_range, $b->end_of_range);
    # end of range is 'B  001100C130D119~999'
    

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

=head2 _normalize(string $lc, boolean $bottom)

Utility function to perform normalization to both start and end
of range, as well as output formats

=cut

sub _normalize {
  my $self = shift;
  my $lc = uc(shift);
  my $bottomout = shift;
  
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
    return $alpha;
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

=head1 AUTHOR

Bill Dueber, C<< <dueberb at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-library-callnumber-lc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Library-CallNumber-LC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Library::CallNumber::LC


You can also look for information at:

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Bill Dueber, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as the new BSD licsense as descirbed at 
http://www.opensource.org/licenses/bsd-license.php


=cut

1; # End of Library::CallNumber::LC
