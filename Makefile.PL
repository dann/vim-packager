use inc::Module::Install;

name     'VIM-Packager';
all_from 'lib/VIM/Packager.pm';
author   q{Cornelius <cornelius.howl@gmail.com>};
license  'perl';


requires(
    'YAML'                        => 0,
    'App::CLI'                    => 0,
    'Getopt::Long'                => 0,
    'DateTime::Format::DateParse' => 0,
    'File::Spec'                  => 0,
    'File::Find'                  => 0,
);
    
build_requires 'Test::More';

auto_install;

WriteAll;

