package VIM::Packager::Command::Init;
use warnings;
use strict;
use File::Path;
use DateTime;
use base qw(App::CLI::Command);

=head1 init

=head2 SYNOPSIS

    $ vim-packager init \
            --name=ohai \
            --type=plugin \
            --name=Cornelius \
            --email=cornelius.howl@gmail.com

=head2 OPTIONS

=over 4

=item --name=[name]  | -n

=item --type=[type]  | -t

=item --author=[author]  | -a

=item --email=[email]  | -e

=item --no-migration | -nm

=back

=cut

sub options {
    (
        'n|name=s'      => 'name',
        'v|verbose'     => 'verbose',
        'nm|no-migration' => 'no_migration',
        't|type=s'      => 'type',
        'a|author=s'    => 'author',
        'e|email=s'     => 'email',
    );
}

sub run {
    my ( $self, @args ) = @_;
    unless($self->{name} and $self->{author} and $self->{email}) {
        print "Please specify --name, --author, --email\n";
        return;
    }

    # migrate dirs
    unless( $self->{no_migration} ) {
        File::Path::mkpath [ 'vimlib' ];
        my @known_dir_names = qw(autoload indent syntax colors doc plugin ftplugin after ftdetect);
        for ( @known_dir_names ) {
            if( -e $_ ) {
                print "$_ directory found , migrate $_ into vimlib/ \n";
                rename $_ , File::Spec->join( 'vimlib', $_ );
            }
        }
    }

    $self->create_dir_skeleton();

    # if we have doc directory , create a basic doc skeleton
    $self->create_doc_skeleton() if( -e File::Spec->join('vimlib' , 'doc') );

    # create meta file skeleton
    $self->create_meta_skeleton( );

    $self->create_readme_skeleton();
}

sub create_readme_skeleton {
    my $self = shift;
    my $cmd = shift;
    
    print "creating README\n";

    open README , ">" , "README";
    print README ""; # XXX
    close README;

}

sub create_doc_skeleton {
    my $self = shift;
    my $name = $self->{name};

    print "Creating doc skeleton.\n";

    open DOC , ">" , File::Spec->join( 'vimlib', 'doc' , "$name.txt" );
    print DOC <<END;

    *$name.txt*  Plugin for .... 

$name                                       *$name* 
Last Change: @{[ DateTime->now ]}

|$name-description|   Description
|$name-syntax|        Syntax
|$name-usage|         Usage
|$name-settings|      Settings
|$name-features|      Features
|$name-contact|       Contact

For Vim version 7.0 or later.
This plugin only works if 'compatible' is not set.
{Vi does not have any of these features.}

==============================================================================
DESCRIPTION                                             *$name-description*

    Your Description here....

==============================================================================
END
        close DOC;
}

sub create_dir_skeleton {
    my $self = shift;
    my $type = $self->{type};

    print "Creating directories.\n";
    # if we get type
    if( $type ) {
        if ( $type eq 'syntax' ) {
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  
                        qw(syntax indent)
            ],1;
        }
        elsif( $type eq 'colors' ) {
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  
                        qw(colors)
            ],1;
        }
        elsif( $type eq 'plugin' ) {
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  
                        qw(plugin doc autoload)
            ],1;
        }
        elsif( $type eq 'ftplugin' ) {
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  
                        qw(ftplugin doc autoload)
            ],1;
        }
    }
    else {
        # create basic skeleton directories
        File::Path::mkpath [
            map { File::Spec->join( 'vimlib' , $_ ) }  
                    qw(autoload plugin syntax doc ftdetect ftplugin)
        ],1;
    }

}

sub create_meta_skeleton {
    my $self = shift;

    print "Writing META.\n";

    open FH, ">", "META";
    print FH <<END;
\n=name           @{[ $self->{name} ]}
\n=author         @{[ $self->{author} ]}
\n=email          @{[ $self->{email} ]}
\n=type           @{[ $self->{type} || '[ script type ]' ]}
\n=version_from   [File]
\n=vim_version    >= 7.2
\n=dependency

    [name] >= [version]

    [name]
        | autoload/libperl.vim | http://github.com/c9s/libperl.vim/raw/master/autoload/libperl.vim
        | plugin/yours.vim | http://ohlalallala.com/yours.vim
\n=script

    # your script files here

\n=repository git://....../

END
    close FH;

}

1;
