package Vim::Packager::Utils;
use warnings;
use strict;


sub findbin {
    my $which = shift;
    my $path  = $ENV{PATH};
    my @paths = split /:/, $path;
    for (@paths) {
        my $bin = $_ . '/' . $which;
        return $bin if ( -x $bin );
    }
}


1;
