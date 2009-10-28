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
    'File::Path'                  => 0,
    'Exporter::Lite'              => 0,
    'LWP::Simple'                 => 0,
    'Carp'                        => 0,
    'Config'                      => 0,
    'DateTime::Format::DateParse' => 0,
    'Exporter::Lite'              => 0,
    'File::Basename'              => 0,
    'File::Copy'                  => 0,
    'File::Find'                  => 0,
    'File::Path'                  => 0,
    'File::Spec'                  => 0,
    'Getopt::Long'                => 0,
    'LWP::Simple'                 => 0,
    'VIM::Packager'               => 0,
    'YAML'                        => 0,
    'App::CLI'                    => 0,
);
    
build_requires 'Test::More';

install_script 'bin/vimpkg';
auto_install;

WriteAll;
