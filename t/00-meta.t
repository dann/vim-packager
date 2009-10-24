
use Test::More tests => 3;
use warnings;
use strict;
use lib 'lib';
BEGIN {
    use_ok('Vim::Packager::Meta');
};

my $meta = Vim::Packager::Meta->new;
ok ( $meta );
$meta->read();
my $meta_object = $meta->meta;
ok( $meta_object );

use Data::Dumper;warn Dumper( $meta_object );






