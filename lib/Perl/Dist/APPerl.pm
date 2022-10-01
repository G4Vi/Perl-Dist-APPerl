package Perl::Dist::APPerl;
# Copyright (c) 2022 Gavin Hayes, see LICENSE in the root of the project
use version; our $VERSION = version->declare("v0.0.1");
use strict;
use warnings;

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

C<apperl-update> does a  C<git pull> for the repos. No arg or C<both>
does both. perl does perl. cosmo does cosmo.

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