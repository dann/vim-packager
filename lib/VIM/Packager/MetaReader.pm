package VIM::Packager::MetaReader;
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

    my $fh = shift;

    my @lines = <$fh>;
    for ( my  $idx = 0 ; $_ = $lines[ $idx ] and $idx < @lines ; $idx ++ ) {
        next if /^#/;    # skip comment
        s/#.*$//;
        s/\s*$//;

        if ( /^=(\w+)/ ) {
            my $dispatch = '__' . $1;
            $class->$dispatch( $_ , \@lines , $idx );
        }
    }

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


}


sub _get_value {
    my $cur = shift;
    my ($v) = ( $cur =~ /^=\w+\s+(.*)$/ ) ;
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


my $package_re = '[0-9a-zA-Z._-]+';



sub trim_comment {
    my $c = shift;
    $c =~ /^#/; # skip comment
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

sub __dependency {
    my ( $self, $cur, $lines, $idx ) = @_;
    $self->meta->{dependency} = [];

    for( $idx++ ; $idx < @$lines ; $idx ++ ) {
        my $cn = $lines->[ $idx + 1 ];
        return if $cn =~ /^=/;

        my $c = trim( $lines->[ $idx ] );
        trim_comment( $c );
        next if blank( $c );


        # for lines like:
        #       plugin.vim  > 1.0
        if( my ( $name , $op , $version ) = ( $c =~ m{
                    ^
                    ($package_re)
                    \s+
                    ([=<>]{1,2})\s+
                    ([0-9a-z.-]+) }x ) )
        {
            push @{ $self->meta->{dependency} }, {
                name => $name,
                op => $op,
                version => $version,
            };
        } 

        # for lines like:
        #       plugin.vim
        #           | plugin/plugin.vim | http://...../.../plugin.vim
        #
        elsif( my ($pkgname) = ( $c =~ m{^($package_re)$} ) ) {
            my @files_to_retrieve = ();
            $idx++;
DEP:
            for( ; $idx < @$lines ; $idx++ )  {
                my $cn = $lines->[ $idx + 1 ];
                last DEP if $cn =~ /^=/;

                my $c = trim($lines->[ $idx ]);
                trim_comment( $c );
                next DEP if blank( $c );

                if( my ($target,$from) = $c =~ m{^\|\s*(.*?)\s*\|\s*(.*)$} ) {
                    push @files_to_retrieve, { from => $from , target => $target };
                }
            }
            push @{ $self->meta->{dependency} }, {
                name => $pkgname,
                files => \@files_to_retrieve ,
            };
        }
    }
}


sub __script {
    my ($self,$cur,$lines,$idx) = @_;
    for( $idx++ ; $idx < @$lines ; $idx ++ ) {
        my $cn = $lines->[ $idx + 1 ];
        return if $cn =~ /^=/;

        my $c = $lines->[ $idx ];
        $c =~ s/^\s*//;
        $c =~ s/\s*$//;
        next if $c =~ /^\s*$/;

        push @{ $self->meta->{script} },  $c;
    }
}

sub __repository {
    my ($self,$cur,$lines,$idx) = @_;
    $self->meta->{repository} = _get_value( $cur );
}

sub __vim_version {
    my ($self,$cur,$lines,$idx) = @_;
    my $v = _get_value( $cur );
    my ( $op , $version ) = $v =~ m/^([<=>]{1,2})\s+([0-9.-a-z]+)/;

    $self->meta->{vim_version} = {
        op => $op,
        version => $version,
    };
}

# some alias
# ....


1;
