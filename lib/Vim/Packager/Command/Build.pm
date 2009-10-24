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
    print STDOUT "Checking if your kit is complete...\n";
    require ExtUtils::Manifest;
    # avoid warning
    $ExtUtils::Manifest::Quiet = $ExtUtils::Manifest::Quiet = 1;
    my(@missed) = ExtUtils::Manifest::manicheck();
    if (@missed) {
        print STDOUT "Warning: the following files are missing in your kit:\n";
        print "\t", join "\n\t", @missed;
        print STDOUT "\n";
        print STDOUT "Please inform the author.\n";
    } else {
        print STDOUT "Looks good\n";
    }
}

sub check_vim_version {

}


1;
