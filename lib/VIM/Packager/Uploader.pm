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

    print "File: $file\n";
    print "VIM Version: $vim_version\n";
    print "Script Version: $script_version\n";
    print "Script ID: $script_id\n";

    require VIM::Uploader;
    my $uploader = VIM::Uploader->new();
    $uploader->login();

    my @lines;
    print "Please enter your release note below (double empty line to finish):\n";
    while( <STDIN> ) {
        chomp ;
        last unless $_ or $lines[ $#lines ];
        push @lines , $_;
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
