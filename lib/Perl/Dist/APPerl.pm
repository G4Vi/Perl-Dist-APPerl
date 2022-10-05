package Perl::Dist::APPerl;
# Copyright (c) 2022 Gavin Hayes, see LICENSE in the root of the project
use version; our $VERSION = version->declare("v0.0.1");
use strict;
use warnings;
use JSON::PP qw(decode_json);
use File::Path qw(make_path);
use Cwd qw(abs_path getcwd);
use Data::Dumper qw(Dumper);

my %defconfig = (
    cosmo_remotes => {
        origin => 'https://github.com/G4Vi/cosmopolitan',
        upstream => 'https://github.com/jart/cosmopolitan',
    },
    perl_remotes => {
        origin => 'https://github.com/G4Vi/perl5',
    },
    apperl_configs => {
        'v5.36.0-full-v0.1.0' => {
            desc => 'Full perl v5.36.0',
            perl_id => 'cosmo-apperl',
            cosmo_id => 'af24c19db395b8edd3f8aab194675eadad173cca',
            cosmo_mode => '',
            cosmo_ape_loader => 'ape-no-modify-self.o',
            perl_flags => ['-Dprefix=/zip', '-Uversiononly', '-Dmyhostname=cosmo', '-Dmydomain=invalid'],
            perl_extra_flags => ['-Doptimize=-Os', '-de'],
            dest => 'perl.com',
        },
        'v5.36.0-full-v0.1.0-vista' => {
            desc => 'Full perl v5.36.0, but with non-standard cosmopolitan libc that still supports vista',
            base => 'v5.36.0-full-v0.1.0',
            perl_id => 'cosmo-apperl-vista',
            cosmo_id => '4381b3d9254d6001f4bead71b458a377e854fbc5',
        },
        'v5.36.0-small-v0.1.0' => {
            desc => 'small perl v5.36.0',
            base => 'v5.36.0-full-v0.1.0',
            perl_extra_flags => ['-Doptimize=-Os', "-Donlyextensions= Cwd Fcntl File/Glob Hash/Util IO List/Util POSIX Socket attributes re ", '-de'],
        },
        'v5.36.0-small-v0.1.0-vista' => {
            desc => 'small perl v5.36.0, but with non-standard cosmopolitan libc that still supports vista',
            base => 'v5.36.0-small-v0.1.0',
            perl_id => 'cosmo-apperl-vista',
            cosmo_id => '4381b3d9254d6001f4bead71b458a377e854fbc5',
        },
        'full' => { desc => 'moving target: full', base => 'v5.36.0-full-v0.1.0' },
        'full-vista' => { desc => 'moving target: full for vista', base => 'v5.36.0-full-v0.1.0-vista' },
        'small' => { desc => 'moving target: small', base => 'v5.36.0-small-v0.1.0' },
        'small-vista' => { desc => 'moving target: small for vista', base => 'v5.36.0-small-v0.1.0-vista' },
        # development configs
        dontuse_threads => {
            desc => "not recommended, threaded build is buggy",
            base => 'v5.36.0-full-v0.1.0',
            perl_extra_flags => ['-Doptimize=-Os', '-Dusethreads', '-de'],
            perl_id => 'cosmo'
        },
        perl_cosmo_dev => {
            desc => "For developing cosmo platform perl without apperl additions",
            base => 'v5.36.0-full-v0.1.0',
            perl_id => 'cosmo'
        },
        perl_cosmo_dev_on_vista => {
            desc => "For developing cosmo platform perl without apperl additions on vista",
            base => "perl_cosmo_dev",
            cosmo_id => '4381b3d9254d6001f4bead71b458a377e854fbc5',
        },
    }
);
my %Configs = %defconfig;
my $projectjsonname = 'apperl-project.json';
my $projectconfig = _load_json($projectjsonname);
if($projectconfig) {
    foreach my $projkey (keys %$projectconfig) {
        if($projkey ne 'apperl_configs') {
            $Configs{$projkey} = $projectconfig->{$projkey};
        }
        else {
            $Configs{$projkey} = {%{$Configs{$projkey}}, %{$projectconfig->{$projkey}}};
        }
    }
}
my $StartDir = getcwd();
my $configdir = $ENV{XDG_CONFIG_HOME} // ($ENV{HOME}.'/.config');
$configdir .= '/apperl';
my $siteconfigpath = "$configdir/site.json";
my $SiteConfig = _load_json($siteconfigpath);
my $CurAPPerlName;
if($SiteConfig) {
    -d $SiteConfig->{cosmo_repo} or die $SiteConfig->{cosmo_repo} .' is not directory';
    -d $SiteConfig->{perl_repo} or die $SiteConfig->{perl_repo} .' is not directory';
    if(exists $SiteConfig->{current_apperl}) {
        $CurAPPerlName = $SiteConfig->{current_apperl};
        exists $Configs{apperl_configs}{$CurAPPerlName} or die("non-existent apperl config $CurAPPerlName in $siteconfigpath");
    }
}

sub Init {
    # determine and validate configuration
    my ($perlrepo, $cosmorepo, $noproject) = @_;
    my $createsiteconfig = ! -e $siteconfigpath;
    die "apperl-init: site config already exists, cannot set repos " if( (defined $perlrepo || defined $cosmorepo) && (! $createsiteconfig));
    my $createprojectconfig = !$noproject && ! -e 'apperl-project.json';
    if(!$createsiteconfig && !$createprojectconfig) {
        print "apperl-init: nothing to init\n";
        return;
    }
    if(defined $perlrepo) {
        $perlrepo = abs_path($perlrepo);
        die "apperl-init: bad perlrepo $perlrepo" unless defined($perlrepo) && -d $perlrepo;
    }
    if(defined $cosmorepo) {
        $cosmorepo = abs_path($cosmorepo);
        die "apperl-init: bad cosmorepo $cosmorepo" unless defined($cosmorepo) && -d $cosmorepo;
    }

    # create project config
    if($createprojectconfig) {
        _write_json($projectjsonname, {
            'apperl-project-desc' => "for project specific apperl configs, this file in meant to be included in version control",
            apperl_configs => {
                'replace_me_with_project_config_name' => {
                    desc => 'description of this config',
                    base => $Configs{apperl_configs}{full}{base},
                    dest => 'perl.com'
                },
            },
        });
        print "apperl-init: wrote project config to $projectjsonname\n";
    }
    else {
        print "apperl-init: skipping writing $projectjsonname\n";
    }

    # create site config
    if($createsiteconfig) {
        my %siteconfig = (
            perl_repo     => $perlrepo // "$configdir/perl5",
            cosmo_repo    => $cosmorepo // "$configdir/cosmopolitan",
            apperl_output => "$configdir/o"
        );
        make_path($configdir);
        _write_json($siteconfigpath, \%siteconfig);
        print "apperl-init: wrote site config to $siteconfigpath\n";
        unless($cosmorepo) {
            _setup_repo($defconfig{cosmo_repo}, $defconfig{cosmo_remotes});
            print "apperl-init: setup cosmopolitan repo\n";
        }
        unless($perlrepo) {
            _setup_repo($defconfig{perl_repo}, $defconfig{perl_remotes});
            print "apperl-init: setup perl repo\n";
        }
    }
    else {
        print "apperl-init: skipping writing $siteconfigpath\n";
    }
    print "apperl-init: done\n";
}

sub Status {
    my @configlist = sort(keys %{$Configs{apperl_configs}});
    foreach my $item (@configlist) {
        print (sprintf "%s %-30.30s | %s\n", $CurAPPerlName && ($item eq $CurAPPerlName) ? '*' : ' ', $item, ($Configs{apperl_configs}{$item}{desc} // ''));
    }
}

sub Set {
    my ($cfgname) = @_;
    defined($SiteConfig) or die "cannot set until initialized (run apperl-init)";
    my $itemconfig = _load_apperl_config($cfgname);
    print Dumper($itemconfig);
    print "cd ".$SiteConfig->{cosmo_repo}."\n";
    chdir($SiteConfig->{cosmo_repo}) or die "Failed to enter cosmo repo";
    _command_or_die('git', 'checkout', $itemconfig->{cosmo_id});

    print "cd ".$SiteConfig->{perl_repo}."\n";
    chdir($SiteConfig->{perl_repo}) or die "Failed to enter perl repo";
    print "make veryclean\n";
    system("make", "veryclean");
    _command_or_die('rm', '-f', 'miniperl.com', 'miniperl.elf', 'perl.com', 'perl.elf');
    _command_or_die('git', 'checkout', $itemconfig->{perl_id});

    $SiteConfig->{current_apperl} = $cfgname;
    _write_json($siteconfigpath, $SiteConfig);
    print "$0: Successfully switched to $cfgname\n";
}

sub Configure {
    defined($SiteConfig) or die "cannot Configure until initialized (run apperl-init)";
    defined($CurAPPerlName) or die "cannot Configure with current apperl set (run apperl-set)";
    my $itemconfig = _load_apperl_config($CurAPPerlName);
    # build cosmo
    print "$0: Building cosmo, COSMO_MODE=$itemconfig->{cosmo_mode} COSMO_APE_LOADER=$itemconfig->{cosmo_ape_loader}\n";
    _command_or_die('make', '-C', $SiteConfig->{cosmo_repo}, '-j4', "MODE=$itemconfig->{cosmo_mode}",
    "o/$itemconfig->{cosmo_mode}/cosmopolitan.a",
    "o/$itemconfig->{cosmo_mode}/libc/crt/crt.o",
    "o/$itemconfig->{cosmo_mode}/ape/public/ape.lds",
    "o/$itemconfig->{cosmo_mode}/ape/$itemconfig->{cosmo_ape_loader}",
    );

    # Finally Configure perl
    print "cd ".$SiteConfig->{perl_repo}."\n";
    chdir($SiteConfig->{perl_repo}) or die "Failed to enter perl repo";
    $ENV{COSMO_REPO} = $SiteConfig->{cosmo_repo};
    $ENV{COSMO_MODE} = $itemconfig->{cosmo_mode};
    $ENV{COSMO_APE_LOADER} = $itemconfig->{cosmo_ape_loader};
    _command_or_die('sh', 'Configure', @{$itemconfig->{perl_flags}}, @{$itemconfig->{perl_extra_flags}}, @_);
    print "$0: Configure successful, time for apperl-build\n";
}

sub Build {
    my ($buildscript) = @_;
    defined($SiteConfig) or die "cannot build until initialized (run apperl-init)";
    defined($CurAPPerlName) or die "cannot Configure with current apperl set (run apperl-set)";
    my $itemconfig = _load_apperl_config($CurAPPerlName);
    print "cd ".$SiteConfig->{perl_repo}."\n";
    chdir($SiteConfig->{perl_repo}) or die "Failed to enter perl repo";
    _command_or_die('make');

    $ENV{PERL_APE} = "$SiteConfig->{perl_repo}/perl.com";
    $ENV{OUTPUTDIR} = "$SiteConfig->{apperl_output}/$CurAPPerlName";
    $ENV{MANIFEST} = "lib bin";
    _command_or_die('sh', $buildscript);
    if(exists $itemconfig->{dest}) {
        print "cd $StartDir\n";
        chdir($StartDir) or die "Failed to restore cwd";
        _command_or_die('cp', "$SiteConfig->{apperl_output}/$CurAPPerlName/perl.com", $itemconfig->{dest});
    }
}

sub _command_or_die {
    print join(' ', @_), "\n";
    system(@_) == 0 or die;
}

sub _setup_repo {
    my ($repopath, $remotes) = @_;
    print "mkdir -p $repopath\n";
    make_path($repopath);
    print "cd $repopath\n";
    chdir($repopath) or die "Failed to chdir $repopath";
    _command_or_die('git', 'init');
    _command_or_die('git', 'checkout', '-b', 'placeholder_dont_use');
    foreach my $remote (keys %{$remotes}) {
        _command_or_die('git', 'remote', 'add', $remote, $remotes->{$remote});
        _command_or_die('git', 'fetch', $remote);
    }
}

sub _write_json {
    my ($destpath, $obj) = @_;
    open(my $fh, '>', $destpath) or die("Failed to open $destpath for writing");
    print $fh JSON::PP->new->pretty->encode($obj);
    close($fh);
}

sub _load_json {
    my ($jsonpath) = @_;
    open(my $fh, '<', $jsonpath) or return undef;
    my $file_content = do { local $/; <$fh> };
    close($fh);
    return decode_json($file_content);
}

sub _load_apperl_config {
    my ($cfgname) = @_;
    exists $Configs{apperl_configs}{$cfgname} or die "Unknown config: $cfgname";
    my %itemconfig = %{$Configs{apperl_configs}{$cfgname}};
    for(my $item = \%itemconfig; exists $item->{base}; ) {
        my $previtem = $item;
        $item = $Configs{apperl_configs}{$item->{base}};
        delete $previtem->{base};
        foreach my $key (keys %{$item}) {
            $itemconfig{$key} = $item->{$key} if(! exists $itemconfig{$key});
        }
    }
    # verify apperl config sanity
    $itemconfig{cosmo_ape_loader} //= 'ape-no-modify-self.o';
    ($itemconfig{cosmo_ape_loader} eq 'ape-no-modify-self.o') || ($itemconfig{cosmo_ape_loader} eq 'ape.o') or die "Unknown ape loader: " . $itemconfig{cosmo_ape_loader};
    return \%itemconfig;
}



1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Dist::APPerl - Actually Portable Perl

=head1 DESCRIPTION

Actually Portable Perl (APPerl) is a distribution of Perl the runs on
several x86_64 operating systems via the same binary. For portability,
it builds to a single binary with perl modules packed inside of it.

This can be used to make cross-platform, single binary, standalone perl
applications; an alternative to L<PAR::Packer>. It also could  allow
easily adding perl into development SDKs, be carried on your USB drive,
or just allow running the exact same perl on multiple computers.

This package documentation covers building APPerl from source,
installation, and usage.

=head1 SYNOPSIS

    apperl-init
    apperl-list
    apperl-set v5.36.0-full
    apperl-list
    apperl-update
    apperl-configure
    apperl-build
    cp "$HOME/.config/apperl/o/v5.36.0-full/perl.com" perl
    ./perl /zip/bin/perldoc perlcosmo
    ./perl --assimilate
    ln -s perl perldoc
    ./perldoc perlcosmo

=head1 BUILDING

=over 4

=item *

C<apperl-init> sets up a build environment for building APPerl and/or
creates an APPerl project file C<apperl-project.json>. Setting up the
build environment entails creating the config file
C<$HOME/.config/apperl/site.json> and setting up the apperl build
dependencies, the perl and cosmopolitan git repos. Setup of either of
the repos can be skipped by passing in the path to the existing repos
with the <-p> for perl or <-c> for cosmo flags. C<apperl-project.json>
is used to specify custom perl builds in your project. Passing <-n>
skips creating the project file. The project file is meant to be kept
in source control. See the source of this file for examples of
C<apperl_configs>.

=item *

C<apperl-list> lists the available APPerl configs. If a current config
is set it is denoted with a C<*>.

=item *

C<apperl-set> sets the current APPerl config, this includes
C<make veryclean> in the Perl repo and C<git checkout> in both Perl and
cosmo repos. The current config name is written to
C<$HOME/.config/apperl/site.json>.

=item *

C<apperl-configure> builds cosmopolitan for the current APPerl config
and runs Perl's C<Configure>

=item *

C<apperl-build> C<make>s perl and builds apperl. The output binary by
default is copied to C<perl.com> in the current directory, set dest in
C<apperl-project.json> to customize output binary path and name.

=back

=head1 INSTALLING

APPerl doesn't need to be installed, the output C<perl.com> binary can
be copied between computers and ran without installation.

However, in certain cases such as magic (modifying $0, etc.) The binary
must be assimilated for it to work properly. Note, you likely want to
copy before this operation as it modifies the binary in-place to be
bound to the current environment.
  cp perl.com perl
  ./perl --assimilate

=head1 USAGE

For the most part, APPerl works like normal perl, however it has a
couple additional features.

=over 4

=item *

C</zip/> filesystem - The APPerl binary is also a ZIP file. Paths
starting with C</zip/> refer to files compressed in the binary itself.
At runtime the zip filesystem is readonly, but additional modules and
scripts can be added just by adding them to the zip file. For example,
perldoc and the other standard scripts are shipped inside of /zip/bin

  ./perl.com /zip/bin/perldoc perlcosmo

=item *

C<argv[0]> script execution - this allows making single binary perl
applications! APPerl built with the APPerl additions
(found in cosmo-apperl branches) attempts to load the argv[0] basename
without extension from /zip/bin

  ln -s perl.com perldoc.com
  ./perldoc.com perlcosmo

=back

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Perl::Dist::APPerl

L<APPerl webpage|https://computoid.com/APPerl/>

Support, and bug reports can be found at the repository
L<https://github.com/G4Vi/APPerl>

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut