package Vim::Packager::Command::Build;
use warnings;
use strict;
use base qw(App::CLI::Command);



sub options { 

}

use YAML;

sub run {
    my ( $self, @args ) = @_;
    my $make = Vim::Packager::MakeMaker->new;

}


1;
