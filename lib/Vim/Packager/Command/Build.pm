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
    $meta->read();
    $meta->convert_to_yaml('META');


}

1;
