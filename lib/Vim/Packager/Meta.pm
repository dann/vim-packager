package Vim::Packager::Meta;
use warnings;
use strict;

my @possible_filename = qw( 
    META
    MEAT.yml
);


sub get_meta_file {
    for my $f ( @possible_filename ) {
        return $f if( -e  $f );
    }
    return undef;
}

sub read {
    my $class = shift;
    my $file = $class->get_meta_file();



}


1;
