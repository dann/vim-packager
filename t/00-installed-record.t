#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 2;
use warnings;
use strict;
use File::Path qw(rmtree mkpath);
use VIM::Packager::MakeMaker;


my $recdir = '/tmp/vimpackager-test/';

my @pkg_record = VIM::Packager::MakeMaker->get_installed_pkgs( $recdir );

is_deeply( \@pkg_record  , [] );


open FH,">", File::Spec->join( $recdir , "aaa" );
print FH "test";
close FH;

open FH,">", File::Spec->join( $recdir , "bbb" );
print FH "orz";
close FH;

@pkg_record = VIM::Packager::MakeMaker->get_installed_pkgs( $recdir );

is_deeply( \@pkg_record , [
          '/tmp/vimpackager-test/aaa',
          '/tmp/vimpackager-test/bbb'
        ]);

rmtree [ $recdir ];
