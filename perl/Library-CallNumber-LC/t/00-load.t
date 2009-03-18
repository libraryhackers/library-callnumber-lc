#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Library::CallNumber::LC' );
}

diag( "Testing Library::CallNumber::LC $Library::CallNumber::LC::VERSION, Perl $], $^X" );
