package Vim::Packager::Meta;
use warnings;
use strict;

use YAML;

my @possible_filename = qw( 
    META
    MEAT.yml
);


sub new { bless {} , shift }

sub meta {
    my $self = shift;
    return $self->{meta} ||= {};
}

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
    my $class = shift;
    my $file = $class->get_meta_file();

    die 'there is no meta file' unless -e $file;

    open my $fh , "<" , $file ;
    my @lines = <$fh>;
    close $fh;

    my $idx = 0;
    for ( @lines ) {
        if ( /^=(\w+)/ ) {
            my $dispatch = '__' . $1;
            $class->$dispatch( $_ , \@lines , $idx );
        }
        $idx++;
    }
}

sub convert_to_yaml {

}

sub _get_value {
    my $cur = shift;
    my ($v) = ( $cur =~ /^=\w+ (.*)$/ ) ;
    return $v;
}

sub __name {
    my ($self,$cur,$lines,$idx) = @_;
    $self->meta->{name} = _get_value( $cur );
}

sub __author {
    my ($self,$cur,$lines,$idx) = @_;
    $self->meta->{author} = _get_value( $cur );
}

sub __version {
    my ($self,$cur,$lines,$idx) = @_;
    $self->meta->{version} = _get_value( $cur );
}

sub __type {
    my ($self,$cur,$lines,$idx) = @_;
    $self->meta->{type} = _get_value( $cur );
}

sub __dependency {
    my ($self,$cur,$lines,$idx) = @_;
    $idx++;
    for( $idx ; $idx < @$lines ; $idx ++ ) {
        my $c = $lines->[ $idx ];
        $c =~ s/^\s*//;
        my ( $name , $op , $version ) = $c =~ m{^([0-9a-zA-Z._-]+)\s+[=<>]{1,2}\s+([0-9a-z.-]+)};
        push @{ $self->meta->{dependency} }, {
            name => $name,
            op => $op,
            version => $version,
        };
    }
}

sub __script {
    my ($self,$cur,$lines,$idx) = @_;

}

sub __repository {
    my ($self,$cur,$lines,$idx) = @_;

}

sub __vim_version {

}

# some alias
# ....


1;
