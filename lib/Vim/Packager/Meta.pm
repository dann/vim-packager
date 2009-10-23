package Vim::Packager::Meta;
use warnings;
use strict;

my @possible_filename = qw( 
    META
    MEAT.yml
);

sub new { bless {} , shift }

sub get_meta_file {
    for my $f ( @possible_filename ) {
        return $f if( -e  $f );
    }
    return undef;
}

=pod Generic VIM Meta file format

    =name       new_plugin
    =author     Cornelius (cornelius.howl@gmail.com)
    =version    0.1
    =version    plugin/new_plugin.vim   # extract version infomation from this file
    =type       syntax
    =dependency
        autocomplpop.vim > 0.3
        rainbow.vim      >= 1.2

    =script
        bin/parser
        bin/template_generator

    =repository git://....../

=cut

sub read {
    my $new = shift;
    my $file = $class->get_meta_file();

    die 'there is no meta file' unless -e $file;

    open my $fh , "<" , $file ;
    my @lines = <$fh>;
    close $fh;

    my $idx = 0;
    for ( @lines ) {
        if ( /^=(\w+)/ ) {
            my $dispatch = '_' . $1;
            $class->$dispatch( $_ , \@lines , $idx );
        }
        $idx++;
    }
}

sub _name {
    my ($self,$cur,$lines,$idx) = @_;

}

sub _author { }
sub _version { }
sub _type { }
sub _dependency { }
sub _script { }
sub _repository { }

# some alias






1;
