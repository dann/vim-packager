use Test::More tests => 16;
use warnings;
use strict;
use lib 'lib';
BEGIN {
    use_ok('VIM::Packager::MetaReader');
};


open FH , ">" , "test.vim";
print FH <<END;

"=VERSION 0.3

END
close FH;

my $sample =<<END;

# comment

=name       new_plugin

# comment

=author     Cornelius (cornelius.howl\@gmail.com)

=version         1.0

=version_from    test.vim   # extract version infomation from this file

=vim_version < 7.2

=type       syntax

=dependency

    autocomplpop.vim > 0.3
            # comments

    rainbow.vim      >= 1.2

    autocomplpop.vim
        | autoload/acp.vim | http://c9s.blogspot.com
        | plugin/acp.vim   | http://plurk.com/c9s

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

is_deeply(
    $meta_object->{dependency} , [ {
                'version' => '0.3',
                'name'    => 'autocomplpop.vim',
                'op'      => '>'
            },
            {
                'version' => '1.2',
                'name'    => 'rainbow.vim',
                'op'      => '>='
            },
            {
                'name' => 'autocomplpop.vim',
                'required_files' => [ {
                        'target' => 'autoload/acp.vim',
                        'from'   => 'http://c9s.blogspot.com'
                    },
                    {
                        'target' => 'plugin/acp.vim',
                        'from'   => 'http://plurk.com/c9s'
                    }
                ],
            }
]);

ok( $meta_object->{$_} ) for qw(repository script version name type author);

is( $meta_object->{repository} , 'git://....../' );
is( $meta_object->{author} , 'Cornelius (cornelius.howl@gmail.com)' );
is( $meta_object->{type} , 'syntax' );
is( $meta_object->{name} , 'new_plugin' );
is( $meta_object->{version} , 0.3 );

is_deeply( $meta_object->{script}, [ 'bin/parser', 'bin/template_generator' ]);

unlink 'test.vim';
