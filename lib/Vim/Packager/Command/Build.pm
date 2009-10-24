package Vim::Packager::Command::Build;
use warnings;
use strict;
use Vim::Packager::MetaReader;
use base qw(App::CLI::Command);

sub options { 

}


sub run {
    my ( $self, @args ) = @_;

    # read meta_reader file
    my $meta_reader = Vim::Packager::MetaReader->new;

    my $file = $meta_reader->get_meta_file();
    die 'there is no meta_reader file' unless -e $file;

    open my $fh , "<" , $file ;
    $meta_reader->read( \$fh );
    close $fh;

    use YAML;
    DumpFile( "meta_reader.yml" , $meta_reader->meta );
}

1;
