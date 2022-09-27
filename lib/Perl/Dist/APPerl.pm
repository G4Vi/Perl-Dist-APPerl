package Perl::Dist::APPerl;
# Copyright (c) 2022 Gavin Hayes, see LICENSE in the root of the project
use version; our $VERSION = version->declare("v0.0.0");
use strict;
use warnings;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Dist::APPerl - Actually Portable Perl

=head1 NOTE

Only manual instructions for building Actually Portable Perl is
included in this dist.

=head1 SYNOPSIS

    git clone https://github.com/jart/cosmopolitan
    git clone https://github.com/G4Vi/perl5
    cd perl5 && git checkout cosmo
    cosmo/superConfigure -de
    make
    cosmo/buildAPPerl.sh

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Perl::Dist::APPerl

Additional documentation, support, and bug reports can be found at the
repository L<https://github.com/G4Vi/APPerl>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut