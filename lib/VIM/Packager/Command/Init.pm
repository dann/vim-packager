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

=item --name=[name]

=item --type=[type]

=item --author=[author]

=item --email=[email]

=back

=cut

sub options { (
        'n|name=s'   => 'name',
        'v|verbose'  => 'verbose',
        't|type=s'   => 'type',
        'a|author=s' => 'author',
        'e|email=s'  => 'email',
) }

sub run {
    my ( $self, @args ) = @_;

    unless($self->{name} and $self->{author} and $self->{email}) {
        print "Please specify --name, --author, --email\n";
        return;
    }


    print "Creating Directories.\n";
    create_dir_skeleton( $self->{type} );

    # if we have doc directory , create a basic doc skeleton
    create_doc_skeleton( $self->{name} ) 
        if( -e File::Spec->join('vimlib' , 'doc') );

    # create meta file skeleton
    print "Writing META.\n";
    $self->create_meta_skeleton( );

}



sub create_doc_skeleton {
    my $name = shift;

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
    my $type = shift;

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
