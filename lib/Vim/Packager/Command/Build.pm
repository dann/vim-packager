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
    $make->init_meta();


    if (-f "MANIFEST" && ! -f "Makefile"){
        check_manifest();
    }


    check_vim_version();

}

sub check_manifest {

}

sub check_vim_version {

}


1;
