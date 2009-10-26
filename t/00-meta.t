
use Test::More tests => 4;
use warnings;
use strict;
use lib 'lib';
BEGIN {
    use_ok('VIM::Packager::MetaReader');
};


my $sample =<<END;

# comment

=name       new_plugin

# comment

=author     Cornelius (cornelius.howl\@gmail.com)
=version    0.1
=version    plugin/new_plugin.vim   # extract version infomation from this file
=vim_version < 7.2
=type       syntax
=dependency
    autocomplpop.vim > 0.3
    rainbow.vim      >= 1.2

=script
    bin/parser
    bin/template_generator

=repository git://....../

END


open my $fh , "<" , \$sample;

my $meta = VIM::Packager::MetaReader->new;
ok ( $meta );
$meta->read( $fh );

close $fh;

my $meta_object = $meta->meta;
ok( $meta_object );


is_deeply( $meta_object , {
          'repository' => 'git://....../',
          'dependency' => [
                            {
                              'version' => '0.3',
                              'name' => 'autocomplpop.vim',
                              'op' => '>'
                            },
                            {
                              'version' => '1.2',
                              'name' => 'rainbow.vim',
                              'op' => '>='
                            }
                          ],
          'script' => [
                        'bin/parser',
                        'bin/template_generator'
                      ],
          'version' => 'plugin/new_plugin.vim',
          'name' => 'new_plugin',
          'type' => 'syntax',
          'author' => 'Cornelius (cornelius.howl@gmail.com)'
});

