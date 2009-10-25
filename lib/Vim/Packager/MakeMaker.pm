package Vim::Packager::MakeMaker;
use warnings;
use strict;

use Vim::Packager::MetaReader;
use DateTime::Format::DateParse;
use YAML;

our $VERSION = 0.0.1;

my $VERBOSE = 1;

sub new { 
    my $self = bless {},shift;
    my $meta = $self->init_meta();

    print STDOUT "Vim::Packager::MakeMaker (v$VERSION)\n" if $VERBOSE;
    if (-f "MANIFEST" && ! -f "Makefile"){
        check_manifest();
    }
    
    my %unsatisfied = ();
    for my $dep ( @{ $meta->{dependency} } ) {
        my $prereq           = $dep->{name};
        my $required_version = $dep->{version};
        my $version_op       = $dep->{op};

        my $installed_files;# XXX: get installed files of prerequire plugins
        # XXX: check if prerequire plugin is installed.

        # XXX: or try to retreive meta information of a package
        my $pr_version = 0 ; $pr_version = parse_version( $installed_files ) if $installed_files;  

        if( ! $installed_files ) {
            warn sprintf "Warning: prerequisite %s - %s not found.\n", 
              $prereq, $required_version
                   ; # unless $self->{PREREQ_FATAL};
            
            $unsatisfied{ $prereq } = 'not installed';
        }
        elsif ( eval "$pr_version $version_op $required_version"  ) {
            warn sprintf "Warning: prerequisite %s - %s not found. We have %s.\n",
              $prereq, $required_version, ($pr_version || 'unknown version') 
                    ; # unless $self->{PREREQ_FATAL};
        }
    }

    if (%unsatisfied && $self->{PREREQ_FATAL}){
        my $failedprereqs = join "\n", map {"    $_ $unsatisfied{$_}"} 
                            sort { $a cmp $b } keys %unsatisfied;
        die <<"END";
MakeMaker FATAL: prerequisites not found.
$failedprereqs

Please install these modules first and rerun 'perl Makefile.PL'.
END
    }
}



sub check_vim_version {
    my $where_is_vim = Vim::Packager::Utils::findbin('vim');

    unless( $where_is_vim ) {
        print STDOUT "It seems you dont have vim installed.";
        die;
    }

    my $version_output = qx{$where_is_vim --version};
    my @lines = split /\n/, $version_output;

    my ( $version, $date_string )
        = $lines[ 0 ] =~ /^VIM - Vi IMproved ([0-9.]+) \((.*?)\)/;

    my ( $revision_date, $compiled_time ) = split /,/, $date_string;

    $compiled_time =~ s/\s*compiled\s*//;
    $compiled_time = DateTime::Format::DateParse->parse_datetime($compiled_time);

    my ($platform) = $lines[ 1 ] =~ /^(.*?) version/;

    # Included patches: 1-264
    my ( $patch_from, $patch_to )
        = $lines[ 2 ] =~ /^Included patches: (\d+)-(\d+)$/;

    # Compiled by [who]
    my ($compiled_by) = $lines[ 3 ] =~ /^Compiled by (.*?)$/;

    return {
        version     => $version,
        platform    => $platform,
        compiled_on => $compiled_time,
        patch_from  => $patch_from,
        patch_to    => $patch_to,
        compiled_by => $compiled_by
    };
}


sub init_meta {
    my $self = shift;
    # read meta_reader file
    my $meta_reader = Vim::Packager::MetaReader->new;

    my $file = $meta_reader->get_meta_file();
    die 'Can not found META file' unless -e $file;

    open my $fh , "<" , $file ;
    $meta_reader->read( $fh );
    close $fh;

    YAML::DumpFile( "META.yml" , $meta_reader->meta );

    return $meta_reader->meta;
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


sub prompt ($;$) {  ## no critic
    my($mess, $def) = @_;
    Carp::confess("prompt function called without an argument") 
        unless defined $mess;

    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";

    local $|=1;
    local $\;
    print "$mess $dispdef";

    my $ans;
    if ($ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
        print "$def\n";
    }
    else {
        $ans = <STDIN>;
        if( defined $ans ) {
            chomp $ans;
        }
        else { # user hit ctrl-D
            print "\n";
        }
    }

    return (!defined $ans || $ans eq '') ? $def : $ans;
}



1;
