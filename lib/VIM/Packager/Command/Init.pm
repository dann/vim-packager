package VIM::Packager::Command::Init;
use warnings;
use strict;
use File::Path;
use base qw(App::CLI::Command);

sub options {
    (
        'n|name'    => 'naame',
        'v|verbose' => 'verbose',
        't|type'    => 'type',
        'a|author'  => 'author',
        'e|email'   => 'email',
    );
}

sub run {
    my ( $self, @args ) = @_;

    unless($self->{name} and $self->{author} and $self->{email}) {
        print "Please specify --name, --author, --email\n";
        return;
    }

    # create basic skeleton directories
    print "Creating Directories.\n";
    File::Path::mkpath [
        map { File::Spec->join( 'vimlib' , $_ ) }  
                qw(plugin syntax doc ftdetect ftplugin)
    ];


    print "Writing META.\n";
    # create meta file skeleton
    open FH, ">", "META";
    print FH <<END;

=name           @{[  $self->{name} ]}

=author         @{[ $self->{author} ]}

=email          @{[ $self->{email} ]}

=version_from   [File]

=vim_version    >= 7.2

=type           @{[ $self->{type} ]}

=dependency

    [name] >= [version]

    [name]
        | autoload/libperl.vim | http://github.com/c9s/libperl.vim/raw/master/autoload/libperl.vim
        | plugin/yours.vim | http://ohlalallala.com/yours.vim

=script

    # your script files here

=repository git://....../

END
    close FH;



}



1;
