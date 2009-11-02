package VIM::Packager::Command::Init;
use warnings;
use strict;
use File::Path;
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
    # if we get type
    if( $self->{type} ) {
        if ( $self->{type} eq 'syntax' ) {
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  
                        qw(syntax indent)
            ],1;
        }
        elsif( $self->{type} eq 'colors' ) {
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  
                        qw(colors)
            ],1;
        }
        elsif( $self->{type} eq 'plugin' ) {
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  
                        qw(plugin doc autoload)
            ],1;
        }
        elsif( $self->{type} eq 'ftplugin' ) {
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

    # if we have doc directory , create a basic doc skeleton
    if( -e File::Spec->join('vimlib' , 'doc') ) {


    }

    # create meta file skeleton
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
