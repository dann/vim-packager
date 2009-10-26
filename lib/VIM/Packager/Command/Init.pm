package VIM::Packager::Command::Init;
use warnings;
use strict;
use base qw(App::CLI::Command);

sub options { 


}

sub run {
    my ( $self, @args ) = @_;

    # create meta file skeleton

    # XXX: 
    open FH, ">", "VIMMETA";
    print FH <<END;

=name           [Name]

=author         [Author]

=version_from   [Version]

=vim_version    >= 7.2

=type           [TYPE]

=dependency

    [name] >= [version]

    [name]
        | autoload/libperl.vim | http://github.com/c9s/libperl.vim/raw/master/autoload/libperl.vim
        | plugin/yours.vim | http://ohlalallala.com/yours.vim

=script

# not implmeneted yet

=repository git://....../

END
    close FH;



}



1;
