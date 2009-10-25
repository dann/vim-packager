package VIM::Packager::Command::Build;
use warnings;
use strict;
use base qw(App::CLI::Command);



sub options { 

}

use YAML;
use VIM::Packager::MakeMaker;

sub run {
    my ( $self, @args ) = @_;
    my $make = VIM::Packager::MakeMaker->new;

}


1;
