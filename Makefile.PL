use inc::Module::Install;

name     'VIM-Packager';
all_from 'lib/VIM/Packager.pm';
author   q{Cornelius <cornelius.howl@gmail.com>};
license  'perl';

requires(
    'App::CLI'                    => 0.08,
    'Carp'                        => 1.11,
    'DateTime::Format::DateParse' => 0.04,
    'Exporter::Lite'              => 0.02,
    'File::Basename'              => 0,
    'File::Copy'                  => 0,
    'File::Find'                  => 1.14,
    'File::Path'                  => 2.07,
    'File::Spec'                  => 3.3,
    'Getopt::Long'                => 2.38,
    'LWP::Simple'                 => 0,
    'YAML'                        => 0.70,
);

feature 'Upload vim script dist to vim.org' =>
    -default => 1,
    recommends('VIM::Uploader' => '0');

feature 'Diff with remote download script' => 
    -default => 1,
    recommends('Algorithm::Diff' => '0');


build_requires 'Test::More';

install_script 'bin/vim-packager';
auto_install;

WriteAll;
