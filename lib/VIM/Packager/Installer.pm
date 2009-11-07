package VIM::Packager::Installer;
use warnings;
use strict;
use File::Spec;
use File::Path;
use File::Copy;
use Exporter::Lite;
use YAML;
use VIM::Packager::Utils qw(vim_rtp_home vim_inst_record_dir findbin);
use LWP::UserAgent;
use VIM::Packager::MetaReader;

our @EXPORT = ();
our @EXPORT_OK = qw(install_deps install install_deps_remote);

# FIXME:  install deps from vim script archive network.

sub install_deps {
    my $deps = shift @ARGV;
    my @pkgs = split /,/,$deps;
    # use Data::Dumper;warn Dumper( \@pkgs );
    die 'please implement me!!!';

    # * foreach dependency

    # * retreive vimscript tarball

    # * untar to build directory

    # * change directory to build directory

    # * read package meta file

    # * check dependency

    # * install dependencies

    # * call VIM::Pacakger::Installer to install files

}


our $VERBOSE = $ENV{VERBOSE} ? 1 : 0;


sub mk_record {
    my $pkgname = shift;
    my $version = shift;
    my $filelist = shift;

}

sub install_deps_remote {
    my $package_name = shift @ARGV;
    my %install = @ARGV;

    print sprintf( "Installing dependencies: %s\n",  $package_name);

    $|++;
    while( my ($target,$from) = each %install ) {

        # XXX: we might need to expand Makefile macro to support such things like:
        #    $(VIM_BASEDIR)/path/to/
        # see VIM::Packager::MakeMaker
        # XXX: we should compare the installed file and the downloaded file.
        $target = File::Spec->join( vim_rtp_home() , $target );

        print "Downloading $from " ;
        print " to " . $target if $VERBOSE;
        print "...";

        {
            my ($v,$dir,$file) = File::Spec->splitpath( $target );
            File::Path::mkpath [ $dir ] unless -e $dir;
        }

        my $ua = LWP::UserAgent->new;
        $ua->timeout( 10 );
        $ua->env_proxy();

        my $content;
        my $response = $ua->get( $from );
        if( $response->is_success ) {
            $content = $response->decoded_content;


            print "[ OK ]\n";
        }
        else {
            print "[ FAIL ]\n";
            print $response->status_line;
        }

        # XXX: try to get the last modified time

        # if target exists , then we should do a diff
        if ( $content and -e $target ) {
            my @src = split /\n/,$content;

            open FH_T , "<", $target;
            my @target = <FH_T>;
            close FH_T;

            chomp @target;
            chomp @src;

            my $diff = diff_base_install( \@src , \@target );
            if ( $diff ) {
                my $ans = prompt_for_different( $target );
                while( $ans =~ /d/i ) {
                    print "Diff:\n";
                    print $diff;
                    $ans = prompt_for_different( $target );
                }
                if( $ans =~ /r/i ) {
                    # do replace
                    open RH,">",$target;
                    print RH join("\n",@src);
                    close RH;
                    print "$target replaced\n";
                }
                elsif ( $ans =~ /s/i ) {
                    # do nothing
                    print "Skipped\n";
                }
            }
        }
        elsif ( $content and ! -e $target ) {
            open RH,">",$target;
            print RH $content;
            close RH;
            print "$target installed\n";
        }


    }
}

sub prompt_for_different {
    my $target = shift;
    print "Installed script version not found. instead , we found the installed script file.\n";
    print "The installed vim script file is different from which you just downloaded.\n";
    print "Which is: $target.\n";
    print "(Replace / Diff / Merge / Skip) it with the remote one ? (r/d/m/s) ";
    my $ans = <STDIN>;
    chomp $ans;
    return $ans;
}


sub diff_base_install {
    my ($src_lines,$to_lines) = @_;
    require Algorithm::Diff;

    my $diff = Algorithm::Diff->new( $src_lines , $to_lines );
    $diff->Base(1);
    
    my $result = "";
    while(  $diff->Next()  ) {
        next   if  $diff->Same();

        my $sep = '';

        if(  ! $diff->Items(2)  ) {
            $result .= sprintf "%d,%dd%d\n", $diff->Get(qw( Min1 Max1 Max2 ));
        } 
        elsif(  ! $diff->Items(1)  ) {
            $result .= sprintf "%da%d,%d\n", $diff->Get(qw( Max1 Min2 Max2 ));
        } 
        else {
            $sep = "---\n";
            $result .= sprintf "%d,%dc%d,%d\n", $diff->Get(qw( Min1 Max1 Min2 Max2 ));
        }  
        $result .= "< $_\n"   for  $diff->Items(1);
        $result .= $sep;
        $result .= "> $_\n"   for  $diff->Items(2);
    }

    return $result ? $result : undef;
}

sub install {
    my %install_to = @ARGV;

    # XXX: we should check more details on those files which are going to be
    #      installed.
    while( my ($from,$to) = each %install_to ){
        my ( $v, $dir, $file ) = File::Spec->splitpath($to);

        print("$from doesnt exist.\n"),next unless -e $from;

        File::Path::mkpath [ $dir ] unless -e $dir ;

        my $mtime_to = (stat($to))[9];
        my $mtime_from = (stat($from))[9];

        if ( $mtime_from > $mtime_to ) {
            File::Copy::copy( $from , $to );
            print STDOUT "Installing $from => $to \n";
        }
        else {
            print STDOUT "Skip $from\n";
        }
    }

    # make installation record
    my $meta = VIM::Packager::MetaReader->new->read_metafile();
    my $files = values %install_to;

    YAML::DumpFile( File::Spec->join( 
        ( $ENV{VIMPKG_RECORDDIR} || File::Spec->join($ENV{HOME},'.vim','record') ),
        $meta->{name} 
      ) , { 
        meta => $meta, 
        files => $files 
    } );

    # XXX: update doc tags
}

1;
