package Vim::Packager::Command::Build;
use warnings;
use strict;
use Vim::Packager::Meta;
use base qw(App::CLI::Command);

sub options { 

}


sub run {
    my ( $self, @args ) = @_;



    # read meta file
    my $meta = Vim::Packager::Meta->new;




}




1;
