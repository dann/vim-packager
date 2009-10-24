package Vim::Packager::Command::Build;
use warnings;
use strict;
use Vim::Packager::MetaReader;
use base qw(App::CLI::Command);

sub options { 

}


sub run {
    my ( $self, @args ) = @_;

    # read meta file
    my $meta = Vim::Packager::MetaReader->new;

    my $file = $meta->get_meta_file();
    die 'there is no meta file' unless -e $file;

    open my $fh , "<" , $file ;
    $meta->read( \$fh );
    close $fh;

    my $meta_o = $meta->meta;
    use YAML;
    DumpFile( "META.yml" , $meta_o );
}

1;
