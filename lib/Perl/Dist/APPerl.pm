package Perl::Dist::APPerl;
# Copyright (c) 2022 Gavin Hayes, see LICENSE in the root of the project
use version; our $VERSION = version->declare("v0.0.1");
use strict;
use warnings;
use JSON::PP qw(decode_json);
use File::Path qw(make_path);
use Cwd 'abs_path';
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
        base => {
            desc => 'Most configs build off of this',
            perl_id => 'cosmo-apperl',
            cosmo_id => 'af24c19db395b8edd3f8aab194675eadad173cca',
            cosmo_mode => '',
            cosmo_ape_loader => 'ape-no-modify-self.o',
            perl_flags => ['-Dprefix=/zip', '-Uversiononly', '-Dmyhostname=cosmo', '-Dmydomain=invalid'],
            perl_extra_flags => ['-Doptimize=-Os', '-de'],
        },
        threads_dontuse => {
            desc => "threaded build is buggy",
            base => 'base',
            perl_extra_flags => ['-Doptimize=-Os', '-Dusethreads', '-de'],
            perl_id => 'cosmo'
        },
        smallwip => {
            desc => "smaller build",
            perl_extra_flags => ['-Doptimize=-Os', "-Donlyextensions= Cwd Fcntl File/Glob IO  re SDBM_File ", '-de'],
            base => 'base',
        },
        'v5.36.0-full' => {
            base => 'base',
        },
        'v5.36.0-full-vista' => {
            base => 'base',
            perl_id => 'cosmo-apperl-vista',
            cosmo_id => '4381b3d9254d6001f4bead71b458a377e854fbc5',
        },
        perl_cosmo_dev => {
            desc => "For developing cosmo platform perl without apperl additions",
            base => 'base',
            perl_id => 'cosmo'
        },
        perl_cosmo_dev_on_vista => {
            desc => "For developing cosmo platform perl without apperl additions on vista",
            base => "v5.36.0-full-vista",
            perl_id => "cosmo",
        },
    }
);
my %Configs = %defconfig;

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
        $Configs{apperl_configs}{$CurAPPerlName}{iscurrent} = 1;
    }
}

sub CreateSiteConfig {
    my ($perlrepo, $cosmorepo) = @_;
    if(defined $perlrepo) {
        $perlrepo = abs_path($perlrepo);
        die "bad perlrepo $perlrepo" unless defined($perlrepo) && -d $perlrepo;
    }
    if(defined $cosmorepo) {
        $cosmorepo = abs_path($cosmorepo);
        die "bad cosmorepo $cosmorepo" unless defined($cosmorepo) && -d $cosmorepo;
    }
    my %siteconfig = (
        perl_repo     => $perlrepo // "$configdir/perl5",
        cosmo_repo    => $cosmorepo // "$configdir/cosmopolitan",
        apperl_output => "$configdir/o"
    );
    my $configpath = "$configdir/site.json";
    die "Error, '$configpath' already exists" if( -e $configpath);
    make_path($configdir);
    _write_json($configpath, \%siteconfig);
    print "Success, wrote default settings to $configpath\n";
    unless($cosmorepo) {
        _setup_repo($defconfig{cosmo_repo}, $defconfig{cosmo_remotes});
        print "Success, setup cosmo repo\n";
    }
    unless($perlrepo) {
        _setup_repo($defconfig{perl_repo}, $defconfig{perl_remotes});
        print "Success, setup perl repo\n";
    }
}

sub Status {
    foreach my $item (keys %{$Configs{apperl_configs}}) {
        print (sprintf "%s $item\n", $Configs{apperl_configs}{$item}{current} ? '*' : ' ');
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
    print "cd ".$SiteConfig->{perl_repo}."\n";
    chdir($SiteConfig->{perl_repo}) or die "Failed to enter perl repo";
    _command_or_die('make');

    $ENV{PERL_APE} = "$SiteConfig->{perl_repo}/perl.com";
    $ENV{OUTPUTDIR} = "$SiteConfig->{apperl_output}/$CurAPPerlName";
    _command_or_die('sh', $buildscript);
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

C<apperl-init> sets up a build environment for building APPerl;
creating the config file C<$HOME/.config/apperl/apperl.json> and sets
up perl and cosmopolitan git repos and does a C<git fetch> on the remotes.
Setup of either of the repos can be skipped by passing in the path to
the existing repos with the <-p> for perl or <-c> for cosmo flags.

=item *

C<apperl-list> lists the available APPerl configs. If a current config
is set it is denoted with a C<*>.

=item *

C<apperl-set> sets the current APPerl config, this includes
C<make veryclean> in the Perl repo and C<git checkout> in both Perl and
cosmo repos. The config name is written to C<~/.config/apperl/current>.

=item *

C<apperl-configure> builds cosmopolitan for the current APPerl config
and runs Perl's C<Configure>

=item *

C<apperl-build> C<make>s perl and builds apperl. The output binary is
available at C<~/.config/apperl/o/configname/perl.com>

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