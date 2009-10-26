package VIM::Packager::Installer;
use warnings;
use strict;
use File::Spec;
use File::Path;
use File::Copy;
use Exporter::Lite;

our @EXPORT = ();
our @EXPORT_OK = qw(install_deps install install_deps_remote);

sub install_deps {
    my @pkgs = @ARGV;
    use Data::Dumper;warn Dumper( \@pkgs );

    # * foreach dependency

    # * retreive vimscript tarball

    # * untar to build directory

    # * change directory to build directory

    # * read package meta file

    # * check dependency

    # * install dependencies

    # * call VIM::Pacakger::Installer to install files

}

sub install_deps_remote {
    my $package_name = shift @ARGV;
    my %install = @ARGV;



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
