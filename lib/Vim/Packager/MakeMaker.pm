package Vim::Packager::MakeMaker;
use warnings;
use strict;

use Vim::Packager::MetaReader;
use YAML;

sub new { bless {},shift }

sub init_meta {
    my $self = shift;
    # read meta_reader file
    my $meta_reader = Vim::Packager::MetaReader->new;

    my $file = $meta_reader->get_meta_file();
    die 'Can not found META file' unless -e $file;

    open my $fh , "<" , $file ;
    $meta_reader->read( $fh );
    close $fh;

    YAML::DumpFile( "META.yml" , $meta_reader->meta );
}


1;
