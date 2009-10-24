package Vim::Packager::Command::Build;
use warnings;
use strict;
use Vim::Packager::MetaReader;
use base qw(App::CLI::Command);

sub options { 

}

use YAML;

sub run {
    my ( $self, @args ) = @_;

    # read meta_reader file
    my $meta_reader = Vim::Packager::MetaReader->new;

    my $file = $meta_reader->get_meta_file();
    die 'Can not found META file' unless -e $file;

    open my $fh , "<" , $file ;
    $meta_reader->read( $fh );
    close $fh;

    YAML::DumpFile( "META.yml" , $meta_reader->meta );
}


sub read_manifest {
    my $self = shift;
    my $file = 'MANIFEST';
    open my $fh , "<" , $file or die "Can not found MANIFEST";
    my @files = <$fh>;
    chomp @files;
    close $fh;
    return \@files;
}

1;
