package VIM::Packager::Installer;
use warnings;
use strict;
use File::Spec;
use File::Path;
use File::Copy;

sub install_deps {
    warn $ENV{DEPS};

    # * foreach dependency

    # * retreive vimscript tarball

    # * untar to build directory

    # * change directory to build directory

    # * read package meta file

    # * check dependency

    # * install dependencies

    # * call VIM::Pacakger::Installer to install files

}

sub install {
    my %install_to = @ARGV;

    while( my ($from,$to) = each %install_to ){
        my ( $v, $dir, $file ) = File::Spec->splitpath($to);
        File::Path::mkpath [ $dir ] unless -e $dir ;
        File::Copy::copy( $from , $to );
        print STDOUT "Installing  $from => $to \n";
    }

    # XXX: update doc tags
}

1;
