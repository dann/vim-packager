package VIM::Packager::Installer;
use warnings;
use strict;
use File::Spec;
use File::Path;
use File::Copy;
use Exporter::Lite;
use VIM::Packager::Utils qw(vim_rtp_home vim_inst_record_dir findbin);

our @EXPORT = ();
our @EXPORT_OK = qw(install_deps install install_deps_remote);

sub install_deps {
    my $deps = shift @ARGV;
    my @pkgs = split /,/,$deps;
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

use LWP::Simple ();
sub install_deps_remote {
    my $package_name = shift @ARGV;
    my %install = @ARGV;

    print sprintf( "Installing %s\n",  $package_name);
    $|++;
    while( my ($target,$from) = each %install ) {

        # XXX: we might expand Makefile variable to support such things like:
        #    $(VIM_BASEDIR)/path/to/
        # see VIM::Packager::MakeMaker
        $target = File::Spec->join( vim_rtp_home() , $target );

        print "Downloading from $from to $target...";

        {
            my ($v,$dir,$file) = File::Spec->splitpath( $target );
            File::Path::mkpath [ $dir ] unless -e $dir;
        }

        my $ret = LWP::Simple::getstore( $from , $target );

        if( $ret eq '200' ) {
            print "[ OK ]\n";
        }
        elsif( $ret eq '404' ) {
            print "[ FAIL: No such file ]\n";
        }
        else {
            print "[ FAIL: Unknown error $ret ]\n";
        }
    }

}

sub install {
    my %install_to = @ARGV;

    while( my ($from,$to) = each %install_to ){
        my ( $v, $dir, $file ) = File::Spec->splitpath($to);
        File::Path::mkpath [ $dir ] unless -e $dir ;
        File::Copy::copy( $from , $to );
        print STDOUT "Installing $from => $to \n";
    }

    # XXX: update doc tags
}

1;
