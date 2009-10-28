package VIM::Packager::Uploader;
use warnings;
use strict;

use Exporter::Lite;

our @EXPORT_OK=qw(upload);


# XXX: currently is for vim.org
sub upload {
    my $file           = shift @ARGV;
    my $vim_version    = shift @ARGV;
    my $script_version = shift @ARGV;

    my $script_id      = shift @ARGV; # vim online script id

    die "you need to specify script_id in your meta file" unless $script_id;

    require VIM::Uploader;
    my $uploader = VIM::Uploader->new();
    $uploader->login();


    my @lines;
    print "Please enter your release note below (double empty line to finish):\n";
    while( <STDIN> ) {
        chomp ;
        push @lines , $_;
        last unless $_ or $lines[ $#lines ];
    }

    my $ok = $uploader->upload( 
        script_id => $script_id ,
        script_file => $file ,
        vim_version => $vim_version,  
        script_version => $script_version,
        version_comment => join("\n",@lines)
    );

    print "DONE" if $ok;
}





1;
