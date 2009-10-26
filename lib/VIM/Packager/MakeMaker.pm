package VIM::Packager::MakeMaker;
use warnings;
use strict;

use VIM::Packager::MetaReader;
use VIM::Packager::Utils;
use DateTime::Format::DateParse;
use YAML;
use File::Spec;
use File::Path;
use File::Find;

our $VERSION = 0.0.1;
my  $VERBOSE = 1;

# perl vim-packager build 
# $ make 
#       # auto install dependency 
# $ make install

sub new { 
    my $self = bless {},shift;
    my $meta = $self->init_meta();


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

    my @result = ();
    push @result, <<'END';
# VIM::Packager::MakeMaker
#
# This Makefile is generated by VIM::Packager::MakeMaker version $VERSION from
# the contents of META . don't edit this file, edit META file instead.
#
# Author: Cornelius
# Email : cornelius.howl@gmail.com
# 

END
    
    my %unsatisfied = $self->check_dependency( $meta );

    my %configs = ();
    my %dir_configs = $self->init_vim_dir_macro();

    my $perl = find_perl();
    die "Can not found perl." unless $perl;
    print STDOUT "Found perl: $perl\n";

    $configs{ FULLPERL } = $perl;
    $configs{ NOECHO } = '@';

    push @result , join "\n",map {  "$_ = " . $configs{ $_ } } sort keys %configs;
    push @result , join "\n",map {  "$_ = " . $dir_configs{ $_ } } sort keys %dir_configs;

    my $filelist = $self->make_filelist();

    my @to_install = keys %$filelist;
    push @result , "TO_INST_VIMS = " . join(" \\\n\t" , @to_install );

    my @vims_to_runtime = %$filelist;
    push @result,"VIMS_TO_RUNT = " . join( " \\\n\t" , @vims_to_runtime );

    # XXX: -Ilib to dev
    push @result , qq|install :|;
    push @result , qq|\n\t\t\$(NOECHO) \$(FULLPERL) -Ilib -MVIM::Packager::Installer=install|
                   . qq| -e 'install()' \$(VIMS_TO_RUNT) |;

    # push @result, "install : \n\t\t echo \$(VIMS_TO_RUNT)";

    # make dependency 
    push @result,"install-deps : ";

    my @pkgs_nonversion = grep { ref($unsatisfied{$_}) eq 'ARRAY' } sort keys %unsatisfied;
    for my $pkgname ( @pkgs_nonversion ) {
        my @nonversion_params = map {  ( $_->{target} , $_->{from} ) } 
            map { @{ $unsatisfied{ $_ } } } $pkgname ;
        push @result,
            qq|\t\t\$(NOECHO) \$(FULLPERL) |
            . qq| -Ilib -MVIM::Packager::Installer=install_deps_remote |
            . qq| -e 'install_deps_remote()' $pkgname @{[ join(' ', @nonversion_params ) ]} |;

    }

    my @pkgs_version = grep {  ref($unsatisfied{$_}) ne 'ARRAY' } sort keys %unsatisfied;
    push @result, <<END;
\t\t\$(NOECHO) \$(FULLPERL) -Ilib -MVIM::Packager::Installer=install_deps        -e 'install_deps()' '@{[ join ",",@pkgs_version ]}' 
END

    print STDOUT "Write to Makefile.\n";
    open FH , ">" , 'Makefile';
    print FH join("\n",@result);
    close FH;
}

sub vim_inst_record_dir { 
    File::Spec->join( $ENV{HOME} , '.vim-packager' , 'installed' ); 
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
            # we can not detect installed package version
            # here is the other way to install dependencies.
            my ( $prereq , $require_files ) = ( $dep->{name}  , $dep->{required_files} );
            $unsatisfied{ $prereq } = $require_files;  # XXX: we should detect for type is arrayref

            for ( @$require_files ) {
                if( $_->{from} ) {
                    warn sprintf "Warning: prerequisite %s - %s not found.\n", 
                }
            }
        }

    }

    return %unsatisfied;
}



sub vim_rtp_home {
    return File::Spec->join( $ENV{HOME} , '.vim' );
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
    my $base_prefix = 'vimlib';
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

sub parse_version {

}

sub vim_version_info {

    # check_vim_version 
    my $where_is_vim = VIM::Packager::Utils::findbin('vim');
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
    my $meta_reader = VIM::Packager::MetaReader->new;

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
