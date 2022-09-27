
#!/usr/bin/perl

use strict;
use warnings;
use Perl::Dist::APPerl;
use Test::Simple tests => 1;

sub getVersion {
    return $Perl::Dist::APPerl::VERSION;
}

ok ( getVersion());
