use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

my %WriteMakefileArgs = (
    NAME             => 'Perl::Dist::APPerl',
    AUTHOR           => "Gavin Hayes <gahayes\@cpan.org>",
    VERSION_FROM     => 'lib/Perl/Dist/APPerl.pm',
    ABSTRACT_FROM    => 'lib/Perl/Dist/APPerl.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        "File::ShareDir::Install" => "0.13"
    },
    PREREQ_PM => {
        'JSON::PP'   => '2.0104',
        'File::Path' => '2.07',
        'version'    => '0.77',
        "File::ShareDir" => 0,
    },
    TEST_REQUIRES => {
        'Test::Pod::LinkCheck::Lite' => '0',
    },
    EXE_FILES => ['script/apperlm'],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => ['Perl-Dist-APPerl-*', '*.com*', 'tests_temp']},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/G4Vi/Perl-Dist-APPerl.git',
                web  => 'https://github.com/G4Vi/Perl-Dist-APPerl',
            },
            bugtracker => {
                web => 'https://github.com/G4Vi/Perl-Dist-APPerl/issues'
            },
            homepage   => 'https://computoid.com/APPerl',
        },
        'dynamic_config' => 0,
        'x_static_install' => 1
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

my %min_eumm_version = (
    CONFIGURE_REQUIRES => '6.52',
    MIN_PERL_VERSION   => '6.48',
    LICENSE            => '6.31',
    META_MERGE         => '6.46',
);
for my $parameter ( keys %min_eumm_version ) {
    delete $WriteMakefileArgs{$parameter}
      unless eval {
          ExtUtils::MakeMaker->VERSION( $min_eumm_version{$parameter} );
          1;
      };
}

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    return File::ShareDir::Install::postamble(@_) . "\n"
    ."authortest: test\n\tAUTHOR_TESTING=1 "
      . $_[0]->test_via_harness( '$(FULLPERLRUN)', 'xt/author/*.t' );
}
