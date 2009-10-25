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
        #      try to get installed package record by vimana manager 
        #      or just look into file and parse the version
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


    my %configure_att ;
    if (defined $self->{CONFIGURE}) {
        if (ref $self->{CONFIGURE} eq 'CODE') {
            %configure_att = %{&{$self->{CONFIGURE}}};
            $self = { %$self, %configure_att };  # merge config
        } else {
            Carp::croak "Attribute 'CONFIGURE' to WriteMakefile() not a code reference\n";
        }
    }



}

# XXX: implement me
sub full_setup {
    my @attrib_help = qw(
        AUTHOR
        NAME
        CONFIGURE
        INST_AUTOLOAD
        INST_PLUGIN
        INST_SYNTAX

        INST_AFTER_PLUGIN
        INST_AFTER_AUTOLOAD
        INST_AFTER_FTPLUGIN
    );

    my @MM_Sections = qw(
        all
        dist
        depend
        install
        clean
        force
    );
}

sub parse_version {

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



=item find_perl

Finds the executables PERL and FULLPERL

=cut

sub find_perl {
    my($self, $ver, $names, $dirs, $trace) = @_;

    if ($trace >= 2){
        print "Looking for perl $ver by these names:
@$names
in these dirs:
@$dirs
";
    }

    my $stderr_duped = 0;
    local *STDERR_COPY;

    unless ($Is{BSD}) {
        # >& and lexical filehandles together give 5.6.2 indigestion
        if( open(STDERR_COPY, '>&STDERR') ) {  ## no critic
            $stderr_duped = 1;
        }
        else {
            warn <<WARNING;
find_perl() can't dup STDERR: $!
You might see some garbage while we search for Perl
WARNING
        }
    }

    foreach my $name (@$names){
        foreach my $dir (@$dirs){
            next unless defined $dir; # $self->{PERL_SRC} may be undefined
            my ($abs, $val);
            if ($self->file_name_is_absolute($name)) {     # /foo/bar
                $abs = $name;
            } elsif ($self->canonpath($name) eq 
                     $self->canonpath(basename($name))) {  # foo
                $abs = $self->catfile($dir, $name);
            } else {                                            # foo/bar
                $abs = $self->catfile($Curdir, $name);
            }
            print "Checking $abs\n" if ($trace >= 2);
            next unless $self->maybe_command($abs);
            print "Executing $abs\n" if ($trace >= 2);

            my $version_check = qq{$abs -le "require $ver; print qq{VER_OK}"};
            $version_check = "$Config{run} $version_check"
                if defined $Config{run} and length $Config{run};

            # To avoid using the unportable 2>&1 to suppress STDERR,
            # we close it before running the command.
            # However, thanks to a thread library bug in many BSDs
            # ( http://www.freebsd.org/cgi/query-pr.cgi?pr=51535 )
            # we cannot use the fancier more portable way in here
            # but instead need to use the traditional 2>&1 construct.
            if ($Is{BSD}) {
                $val = `$version_check 2>&1`;
            } else {
                close STDERR if $stderr_duped;
                $val = `$version_check`;

                # 5.6.2's 3-arg open doesn't work with >&
                open STDERR, ">&STDERR_COPY"  ## no critic
                        if $stderr_duped;
            }

            if ($val =~ /^VER_OK/m) {
                print "Using PERL=$abs\n" if $trace;
                return $abs;
            } elsif ($trace >= 2) {
                print "Result: '$val' ".($? >> 8)."\n";
            }
        }
    }
    print STDOUT "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


1;
