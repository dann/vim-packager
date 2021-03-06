package VIM::Packager::MakeMaker;
use warnings;
use strict;

use VIM::Packager::MetaReader;
use VIM::Packager::Utils qw(vim_rtp_home vim_inst_record_dir findbin);
use DateTime::Format::DateParse;
use YAML;
use File::Spec;
use File::Path;
use File::Find;

our $VERSION = 0.0.1;
my  $VERBOSE = 1;

use constant {
    LIBPATH  => 'vimlib',
};

=head1 SYNOPSIS

    $ vim-packager build 
    $ make 
        # auto install dependency 
    $ make install

=cut


sub multi_line {
    my @items = @_;
    return join " \\\n\t", @items ;
}

sub add_macro  {
    my $ref = shift;
    my ( $name, $content ) = @_;
    push @{ $ref } , qq|$name = $content|;
}

sub new_section {
    my $ref = shift;
    my ( $name , @deps ) = @_;
    push @{ $ref } , qq|| , qq|$name : | . join( " ", @deps );
}

sub add_st {
    my $ref = shift;
    my $st = shift;
    push @{ $ref } , qq|\t\t| . $st;
}

sub meta {
    my $self = shift;
    $self->{meta} = shift if @_;
    return $self->{meta};
}

sub add_noop_st {
	add_st $_[0] => q|$(NOECHO) $(NOOP)|;
}

sub new { 
    my $class = shift;
    my $cmd = shift;  # command object

    my $self = bless {}, $class;
    my $meta = VIM::Packager::MetaReader->new->read_metafile();


    $self->{cmd} = $cmd;

    YAML::DumpFile( "VIMMETA.yml" , $meta );

    $self->meta( $meta ); # save meta object

    my $makefile = {};
    $makefile->{meta} = $meta;

    {
        my $info = vim_version_info();

        my $op = $meta->{vim_version}->{op} ;
        my $version = $meta->{vim_version}->{version} ;

        my $installed_vim_version = $info->{version};

        print STDOUT "Found installed VIM, version $installed_vim_version\n";

        unless( eval "$installed_vim_version $op $version" ) {
            print STDOUT "This distrubution needs a newer vim ( $version )\n";
            die;
        }
    }

    print STDOUT "VIM::Packager::MakeMaker (v$VERSION)\n" if $VERBOSE;
    if (-f "MANIFEST" && ! -f "Makefile"){
        check_manifest();
    }

    my $main = [ ];

    push @$main, q|.PHONY: all install clean uninstall help upload link|;
    
    my $filelist = $self->make_filelist();

    $makefile->{filelist} = $filelist;

    my @meta_section   = $self->meta_section( $meta );
    my @config_section = $self->config_section();
    my @file_section   = $self->file_section( $filelist );

    $self->section_all( $main );
    $self->section_install( $main );

    # main install section
    $self->section_pure_install( $main , $makefile );

    # dependency section
    $self->section_deps( $main );
    $self->section_link( $main , $filelist );

    # -----------

    new_section $main => 'manifest';
    add_st $main => q|$(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Manifest=mkmanifest -e 'mkmanifest'|;
    add_st $main => q|$(NOECHO) $(TOUCH) MANIFEST.SKIP|;

    new_section $main => 'dist';
    add_st $main => q|$(TAR) $(TARFLAGS) $(DISTNAME).tar.gz $(TO_INST_VIMS)|;
	add_noop_st $main;

    new_section $main => 'help';
    add_st $main => q|perldoc VIM::Packager|;

    new_section $main => 'uninstall';
    for( values %$filelist ) {
        add_st $main => q|$(RM_F) | . $_ ;
    }

    # XXX: prompt user to uninstall depedencies

    new_section $main => 'upload' , qw(dist);
    add_st $main => q|$(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Uploader=upload -e 'upload()' |
                . multi_line qw|$(PWD)/$(DISTNAME).tar.gz $(VIM_VERSION) $(VERSION) $(SCRIPT_ID)|;

    new_section $main => 'clean';
    add_st $main      => multi_line q|$(RM)|, qw(pure_install install-deps);
    add_st $main      => q|$(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD)|;


    $self->generate_makefile( [
            { meta   => \@meta_section },
            { config => \@config_section },
            { file   => \@file_section },
            { main   => $main } ] );
}




sub section_all {
    my $self = shift;
    my $main = shift;
    new_section $main => "all" => qw(install-deps);
	add_noop_st $main;
}

sub section_install {
    my $self = shift;
    my $main = shift;
    new_section $main => "install" => qw(pure_install install-deps) ;
	add_noop_st $main;
}

sub section_pure_install {
    my ($self,$main,$makefile) = @_;

    new_section $main => "pure_install";

    # pure makefile option let 
    # makefile doesnt depend on perl module.
    if ( $self->{cmd}->{pure} ) {
        print "Making pure makefile (not to depend on perl module)\n";

        my %files = %{ $makefile->{filelist} };
        
        while ( my ($from,$to) = each %files ) {
            add_st $main => sprintf( q|$(CP) %s %s| , $from , $to );
        }
    }
    else {

        add_st $main =>
            q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=install|
            . q| -e 'install()' $(VIMS_TO_RUNT) |;

        add_st $main =>
            q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=install|
            . q| -e 'install()' $(BIN_TO_RUNT) |;
    }
}

sub section_deps {
    my $self = shift;
    my $main = shift;

    new_section $main => "install-deps";

    if( $self->{cmd}->{pure} ) {
        print "You are making a pure makefile that doesn't depend on perl module.\n";
        print "We are going to skip deps section.\n";
        add_noop_st $main;
        return;
    }


    my %unsatisfied = $self->check_dependency( $self->meta );
    my @pkgs_nonversion = grep { ref($unsatisfied{$_}) eq 'ARRAY' } sort keys %unsatisfied;
    for my $pkgname ( @pkgs_nonversion ) {
        my @nonversion_params = map {  ( $_->{target} , $_->{from} ) } 
            map { @{ $unsatisfied{ $_ } } } $pkgname ;

        add_st $main => multi_line q|$(NOECHO) $(FULLPERL) $(PERLFLAGS)|
                    . qq| -MVIM::Packager::Installer=install_deps_remote |
                    . qq| -e 'install_deps_remote()' $pkgname | 
                    , @nonversion_params ;

    }

    my @pkgs_version = grep {  ref($unsatisfied{$_}) ne 'ARRAY' } sort keys %unsatisfied;
    if( @pkgs_version > 0 ) {
        add_st $main => q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=install_deps  |
                . qq| -e 'install_deps()' '@{[ join ",",@pkgs_version ]}' |;
    }
}


sub section_link {
    my ($self,$main , $filelist) = @_;
    new_section $main => 'link';
    while( my ($src,$target) = each %$filelist ) {
        add_st $main => q|$(NOECHO) $(LN_S) | . File::Spec->join( '$(PWD)' , $src )  . " " .  $target;
    }
    new_section $main => 'link-force';
    while( my ($src,$target) = each %$filelist ) {
        add_st $main => q|$(NOECHO) $(LN_SF) | . File::Spec->join( '$(PWD)' , $src ) . " " .  $target;
    }

    new_section $main => 'unlink';
    while( my ($src,$target) = each %$filelist ) {
        add_st $main => q|$(NOECHO) $(RM) | . $target;
    }
}


sub generate_makefile {
    my $self = shift;
    my $sections = shift;
    

    print "Write to Makefile.\n";

    open my $fh , ">" , 'Makefile';
    print $fh <<'END';
# VIM::Packager::MakeMaker
#
# This Makefile is generated by VIM::Packager::MakeMaker version $VERSION from
# the contents of META . don't edit this file, edit META file instead.
#
# Author: Cornelius
# Email : cornelius.howl@gmail.com
# 

END
    for my $s ( @$sections ) {
        my $n = (keys %$s)[0];
        my $list = $s->{$n};
        print $fh "\n" for ( 1 .. 3 );
        print $fh sprintf("# -------- %s section ------\n" , $n );
        print $fh join("\n", @$list );
        print $fh "\n" for ( 1 .. 2 );
    }
    close $fh;
    print "DONE\n";
}


sub meta_section {
    my $self = shift;
    my $meta = shift;
    my @section = ();
    map { add_macro \@section, uc($_) => $meta->{$_} } grep { ! ref $meta->{$_} } keys %$meta;

    my $distname = $meta->{name};
    $distname =~ tr/._/--/;
    $distname .= '-' . $meta->{version};
    add_macro \@section , DISTNAME => $distname;

    # XXX: op skipeed
    add_macro \@section , VIM_VERSION => $meta->{vim_version}->{version};

    return @section;
}

sub config_section {
    my $self = shift;

    my @section = ();

    my %configs = ();
    my %dir_configs = $self->init_vim_dir_macro();

    my $perl = find_perl();
    die "Can not found perl." unless $perl;

    $configs{FULLPERL} ||= $perl;
    $configs{NOECHO}   ||= '@';
    $configs{TOUCH}    ||= 'touch';
    $configs{ECHO}     ||= 'echo';
    $configs{ECHO_N}   ||= 'echo -n';
    $configs{RM_F}     ||= "rm -vf";
    $configs{RM_RF}    ||= "rm -rf";
    $configs{TEST_F}   ||= "test -f";
    $configs{CP}       ||= "cp";
    $configs{MV}       ||= "mv";
    $configs{CHMOD}    ||= "chmod";
    $configs{FALSE}    ||= 'false';
    $configs{TRUE}     ||= 'true';
    $configs{NOOP}     ||= '$(TRUE)';
    $configs{LN_S}     ||= 'ln -sv';
    $configs{LN_SF}     ||= 'ln -svf';
    $configs{PWD}      ||= '`pwd`';
    $configs{CP}       ||= 'cp -v';

    $configs{FIRST_MAKEFILE} ||= 'Makefile';
    $configs{MAKEFILE_OLD}   ||= 'Makefile.old';

    $configs{TAR} ||= 'COPY_EXTENDED_ATTRIBUTES_DISABLE=1 COPYFILE_DISABLE=1 tar';
    $configs{TARFLAGS} ||= 'cvzf';

    $configs{PERLFLAGS} ||= ' -Ilib ';

    map { add_macro \@section, $_ => $configs{$_} } sort keys %configs;
    map { add_macro \@section, $_ => $dir_configs{$_} } sort keys %dir_configs;
    return @section;
}

sub file_section {
    my $self = shift;
    my $filelist = shift;
    my $meta = $self->meta;

    my @section  = ();

    my @to_install = keys %$filelist;

    add_macro \@section , VIMLIB => LIBPATH;
    add_macro \@section , VIMMETA => VIM::Packager::MetaReader::find_meta_file();

    add_macro \@section , TO_INST_VIMS => multi_line @to_install ;

    my @vims_to_runtime = %$filelist;
    add_macro \@section , VIMS_TO_RUNT => multi_line @vims_to_runtime ;

    my %bin_to_runtime = ();

    if( $meta->{script} ) {
        my @bin = @{ $meta->{script} };
        for (@bin) {
            my ( $v, $d, $f ) = File::Spec->splitpath($_);
            # $bin_to_runtime{ $_ } =  File::Spec->join( vim_rtp_home() , 'bin' , $f );
            $bin_to_runtime{$_} = File::Spec->join( '$(VIM_BASEDIR)', 'bin', $f );
        }
        add_macro \@section , TO_INST_BIN => multi_line keys %bin_to_runtime ;
        add_macro \@section , BIN_TO_RUNT => multi_line %bin_to_runtime ;
    }
    return @section;
}

sub get_installed_pkgs {
    my ($self, $dir ) = @_;

    unless( -e $dir ) {
        File::Path::mkpath [ $dir ];
        return ();
    }

    my @pkg_record_files = ();
    my $closure = sub { 
        my $file = $_;
        my $dir  = $File::Find::dir;

        return unless -f $file;

        my $path = File::Spec->join($dir , $file );
        push @pkg_record_files , $path;
    };

    File::Find::find( \&$closure ,$dir );
    return @pkg_record_files;
}

sub check_dependency {
    my $self = shift;
    my $meta = shift;

    my $record_dir  = $self->vim_inst_record_dir();
    my @pkg_records = $self->get_installed_pkgs($record_dir);

    my %unsatisfied = ();
    for my $dep ( @{ $meta->{dependency} } ) {

        if ( defined $dep->{version} ) {
            my ( $prereq, $required_version, $version_op ) = @$dep{qw(name version op)};

            my $installed_files;  # XXX: get installed files of prerequire plugins

            # XXX: check if prerequire plugin is installed. 
            #      try to get installed package record by vimana manager 
            #      or just look into file and parse the version
            my $pr_version = 0 ; $pr_version = parse_version( $installed_files ) if $installed_files;  

            if( ! $installed_files ) {
                warn sprintf "Warning: prerequisite %s - %s not found.\n", 
                $prereq, $required_version;

                $unsatisfied{ $prereq } = 'not installed';
            }
            elsif ( eval "$pr_version $version_op $required_version"  ) {
                warn sprintf "Warning: prerequisite %s - %s not found. We have %s.\n",
                    $prereq, $required_version, ($pr_version || 'unknown version') ;
                $unsatisfied{ $prereq } = $pr_version;
            }
        }
        else {
            # if we can not detect installed package version
            # here is the other way to install dependencies.
            my ( $prereq , $require_files ) = ( $dep->{name}  , $dep->{required_files} );
            $unsatisfied{ $prereq } = $require_files; 

            # XXX: grep out ?
            for ( @$require_files ) {
                # XXX: expand Makefile variable to support such things like:
                #    $(VIM_BASEDIR)/path/to/
                my $target_path =  File::Spec->join( vim_rtp_home() , $_->{target} ) ;

                unless( -e $target_path ) {
                    warn sprintf "Warning: prerequisite %s - %s not found.\n\tWill be retreived from %s\n", 
                            $prereq , $target_path , $_->{from} ;
                }
                else {
                    printf "[ %s : %s ] ....  OK\n" , $prereq , $_->{target} ;
                }
            }
        }

    }

    return %unsatisfied;
}




sub init_vim_dir_macro {
    my $self = shift;
    my %dir_configs = ();
    $dir_configs{ VIM_BASEDIR } = $ENV{VIM_BASEDIR} || vim_rtp_home();
    $dir_configs{ VIM_AFTERBASE_DIR} = $ENV{VIM_AFTERBASE_DIR}  || File::Spec->join( $dir_configs{VIM_BASEDIR} , 'after' );

    for my $sub ( qw(after syntax ftplugin compiler plugin macros colors) ) {
        my $path_name = 'VIM_' . uc($sub) . '_DIR';
        my $after_path_name = 'VIM_AFTER_' . uc($sub) . '_DIR';
        $dir_configs{$path_name} = $ENV{$path_name}
            || File::Spec->join( $dir_configs{VIM_BASEDIR}, $sub );

        $dir_configs{$after_path_name} = $ENV{$after_path_name}
            || File::Spec->join( $dir_configs{VIM_BASEDIR}, $sub );
    }
    return %dir_configs;
}


sub make_filelist {
    my $self = shift;

    my %install = ();
    my $base_prefix = LIBPATH;

    # my $prefix = File::Spec->join($ENV{HOME} , '.vim');
    my $prefix = '$(VIM_BASEDIR)';
    File::Find::find( sub {
        return unless -f $_;
        return if /\#/;
        return if /~$/;             # emacs temp files
        return if /,v$/;            # RCS files
        return if m{\.swp$};        # vim swap files

        my $src = File::Spec->catfile( $File::Find::dir , $_ );

        my $target;
        ( $target = $src ) =~ s{^$base_prefix/}{};
        $target = File::Spec->catfile( $prefix , $target );

        $install{ $src } = $target;
    } , $base_prefix );
    return \%install;
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


# XXX:
# parse version from vim runtime path files
# neeed to find a way to do it
sub parse_version {

}

sub vim_version_info {

    # check_vim_version 
    my $where_is_vim = findbin('vim');
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

use File::Spec;
sub find_perl {
    my @paths = split /:/,$ENV{PATH};
    my @names = qw(perl);
    for my $path ( @paths ) {
        for my $name ( @names ) {
            my $abspath = File::Spec->join( $path , $name );
            return $abspath if -e $abspath;
        }
    }
    return undef;
}


1;
