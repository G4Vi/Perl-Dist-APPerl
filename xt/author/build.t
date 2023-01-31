#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Perl::Dist::APPerl;
use File::Copy "cp";
#my @apperlconfigs = qw(full small full-vista small-vista nobuild-v0.1.0);
my @apperlconfigs = qw(nobuild-v0.1.0);
#my @apperlconfigs = qw(small);
plan tests => 3 * scalar(@apperlconfigs);

my %binmapping = (
    full => 'perl.com',
    small => 'perl-small.com',
    'full-vista' => 'perl-vista.com',
    'small-vista' => 'perl-small-vista.com',
    'nobuild-v0.1.0' => 'perl-nobuild.com'
);

foreach my $config (@apperlconfigs) {
    SKIP: {
        skip "$config bin already exists", 3 if( -e $binmapping{$config});
        my $isnobuild = $config =~ /nobuild/;
        if($isnobuild) {
            mkdir('src');
            cp('perl.com', 'src/perl.com');
            system('chmod', '+x', 'src/perl.com');
        }
        while(1) {
            my $ret = hide_out_and_err(sub { Perl::Dist::APPerl::apperlm('checkout', $config); });
            ok($ret, "apperlm checkout $config");
            $ret or last;
            SKIP: {
                skip "nobuild configs do not configure", 1 if($isnobuild );
                $ret = hide_out_and_err(sub { Perl::Dist::APPerl::apperlm('configure'); });
                ok($ret, "apperlm configure ($config)");
                $ret or last;
            }
            $ret = hide_out_and_err(sub { Perl::Dist::APPerl::apperlm('build'); });
            ok($ret, "apperlm build ($config)");
            last;
        }
    }
}

sub hide_out_and_err {
    my ($callback) = @_;
    return $callback->();
    open(my $saved_stderr, '>&', STDERR) or die "$!";
    open(my $saved_stdout, '>&', STDOUT) or die "$!";
    close(STDERR);
    close(STDOUT);
    open(STDOUT, '>', '/dev/null') or die "$!";
    open(STDERR, '>', '/dev/null') or die "$!";
    my $ret = $callback->();
    close(STDERR);
    open(STDERR, '>&', $saved_stderr) or die "$!";
    close(STDOUT);
    open(STDOUT, '>&', $saved_stdout) or die "$!";
    return $ret;
}
