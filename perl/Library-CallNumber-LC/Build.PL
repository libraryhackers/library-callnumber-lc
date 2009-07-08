use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Library::CallNumber::LC',
    license             => 'perl',
    dist_author         => 'Bill Dueber <dueberb@umich.edu>',
    dist_version_from   => 'lib/Library/CallNumber/LC.pm',
    build_requires => {
        'Test::More' => 0,
        'Math::BigInt' => 0,
    },
    add_to_cleanup      => [ 'Library-CallNumber-LC-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
