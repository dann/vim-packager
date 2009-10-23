use inc::Module::Install;

name     'Vim-Packager';
all_from 'lib/Vim/Packager.pm';
author   q{Cornelius <cornelius.howl@gmail.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

