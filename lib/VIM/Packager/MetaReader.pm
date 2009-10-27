package VIM::Packager::MetaReader;
use warnings;
use strict;

use YAML;

my @possible_filename = qw( 
    VIMMETA
    VIMMETA.yml
);

sub new { bless {} , shift }

sub meta { my $self = shift; return $self->{meta} ||= {}; }

sub get_meta_file {
    for my $f ( @possible_filename ) {
        return $f if( -e  $f );
    }
    return undef;
}

=pod Generic VIM Meta file format

    =name            new_plugin

    =author          Cornelius (cornelius.howl@gmail.com)

    =version_from    plugin/new_plugin.vim   # extract version infomation from this file

    =type            syntax

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

    my $fh = shift;

    my @lines = <$fh>;

    my $cur_section;
    my %sections = ();
    for ( @lines ) {
        chomp;
        $_ = trim_comment($_);
        $_ = trim( $_ );
        next if blank($_);

        if( /^=(\w+)(?:\s+(.*?))?$/ ) {
            $cur_section = $1;
            $sections{ $cur_section} = $2 if $2;
            next;
        }

        push @{ $sections{ $cur_section } } , $_;
    }


    for my $sec ( keys %sections ) {
        my $lines = $sections{ $sec };
        my $dispatch = '__' . $sec;
        if( $class->can( $dispatch ) )  {
            $class->$dispatch( $lines );
        }
        else {
            print "meta tag $1 is not supported.\n";
        }

    }
=pod

    # check for mandatory meta info
    my $fall;
    my $meta = $class->meta;
    for ( qw(name author version type vim_version) ) {
        if( ! defined $meta->{ $_ } ) {
            print STDOUT "META: column '$_' is required. ";
            $fall = 1;
        }
    }
    die if $fall;
=cut

}

my $package_re = '[0-9a-zA-Z._-]+';

sub trim_comment {
    my $c = shift;
    $c =~ s/#.*$//; # skip comment
    return $c;
}

sub trim {
    my $c = shift;
    $c =~ s/^\s*//;
    $c =~ s/\s*$//;
    return $c;
}

sub blank {
    my $c = shift;
    return $c =~ /^\s*$/;
}


sub _get_value {
    my $cur = shift;
    my ($v) = ( $cur =~ /^=\w+\s+(.*)$/ ) ;
    return $v;
}

sub __name {
    my ($self,$value) = @_;
    $self->meta->{name} =$value;
}

sub __author {
    my ($self,$value) = @_;
    $self->meta->{author} =$value;
}

sub __version {
    my ($self,$value) = @_;
    $self->meta->{version} =$value;
}

sub __type {
    my ($self,$value) = @_;
    $self->meta->{type} =$value;
}

sub __version_from {
    my ($self,$version_file) = @_;

    open FH, "<" , $version_file;
    my @lines = <FH>;
    close FH;
    
    for ( @lines ) {
        if( /^"=VERSION/ ) {
            my $line = $_;
            chomp $line;
            $line =~ s/^"//;
            $self->meta->{version} = _get_value( $line );
            return;
        }
    }
    print "Warning: Can not found version, you should declare your version in your vim script.\n";
    print "For example \n";
    print " \"=VERSION 0.3 \n";
}


sub __dependency {
    my ( $self, $lines ) = @_;
    $self->meta->{dependency} = [];

    my %pkgs = ();
    my $cur_name;
    for ( @$lines ) {

        # for lines like:
        #       plugin.vim  > 1.0
        if( m{^ ($package_re) \s+ ([=<>]{1,2})\s+ ([0-9a-z.-]+) }x ) {
            my ( $name, $op, $version ) = ( $1, $2, $3 );

            $pkgs{ $name } = {
                name => $name,
                op => $op,
                version => $version,
            };
            next;
        }

        # for lines like:
        #       plugin.vim
        #           | plugin/plugin.vim | http://...../.../plugin.vim
        elsif( m{^($package_re)$} ) {
            $cur_name = $1;
            next;
        }
        elsif( m{^\|\s*(.*?)\s*\|\s*(\S+)} ) {
            my ( $target, $from ) = ( $1, $2 );
            push @{ $pkgs{ $cur_name } } , {  from => $from , target => $target  };
        }

    }

    $self->meta->{dependency}
        = [ map { { name => $_ , required_files => $pkgs{ $_ } } } keys %pkgs ];
}


sub __script {
    my ( $self, $lines ) = @_;
    $self->meta->{script} = $lines;
}

sub __repository {
    my ( $self, $value ) = @_;
    $self->meta->{repository} = $value;
}

sub __vim_version {
    my ( $self , $v ) = @_;
    my ( $op , $version ) = $v =~ m/^([<=>]{1,2})\s+([0-9.-a-z]+)/;
    $self->meta->{vim_version} = {
        op => $op,
        version => $version,
    };
}

# some alias
# ....


1;
