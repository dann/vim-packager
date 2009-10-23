#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Vim::Packager' );
}

diag( "Testing Vim::Packager $Vim::Packager::VERSION, Perl $], $^X" );
