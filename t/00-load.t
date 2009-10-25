#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VIM::Packager' );
}

diag( "Testing VIM::Packager $VIM::Packager::VERSION, Perl $], $^X" );
