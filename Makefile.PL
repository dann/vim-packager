use inc::Module::Install;

name     'Vim-Packager';
all_from 'lib/Vim/Packager.pm';
author   q{Cornelius <cornelius.howl@gmail.com>};
license  'perl';


requires 
    'YAML' => 0,
    'App::CLI' => 0,
    'Getopt::Long' => 0;
    
build_requires 'Test::More';

auto_install;

WriteAll;

