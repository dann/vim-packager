#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 10;
use warnings;
use strict;

use VIM::Packager::MakeMaker;
my $recdir = '/tmp/vimpackager-test/';

my @pkg_record = VIM::Packager::MakeMaker->get_installed_pkgs( $recdir );

is_deeply( \@pkg_record  , [] );

use File::Path qw(rmtree mkpath);


rmtree [ $recdir ];


