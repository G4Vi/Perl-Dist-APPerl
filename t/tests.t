#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
# Perl::Dist::APPerl currently loads apperl-project.json from the current directory, so hack the cwd
BEGIN {
    $0 = abs_path($0);
    foreach my $inc (@INC) {
        $inc = abs_path($inc);
    }
    mkdir('tests_temp');
    chdir('tests_temp');
    {
        open(my $fh, '>', 'apperl-project.json') or die "unable to write apperl-project.json";
        print $fh '{"defaultconfig":"hello","apperl_configs":{"hello":{"dest":"hello.com","base":"nobuild-v0.1.0","default_script":"/zip/bin/hello","zip_extra_files":{"bin":["src/hello"]}}}}';
        close($fh);
    }
}
use Perl::Dist::APPerl;
use File::Copy "cp";
my @apperlconfigs = qw(hello);
if(! -e 'src/perl.com') {
    if(! -e '../perl.com') {
        plan skip_all => 'Cannot build without perl.com';
    }
    mkdir('src');
    cp('../perl.com', 'src/perl.com');
    my $perm = (stat('src/perl.com'))[2] & 07777;
    chmod($perm | 0111, 'src/perl.com');
}

plan tests => 2 * scalar(@apperlconfigs);

open(my $hh, '>', 'src/hello') or die "unable to write src/hello";
print $hh <<'HELLO';
print "hello\n";
HELLO
close($hh);

foreach my $config (@apperlconfigs) {
    while(1) {
        my $ret = hide_out_and_err(sub { Perl::Dist::APPerl::apperlm('checkout', $config); });
        ok($ret, "apperlm checkout $config");
        $ret or last;
        $ret = hide_out_and_err(sub { Perl::Dist::APPerl::apperlm('build'); });
        ok($ret, "apperlm build ($config)");
        last;
    }
}

sub hide_out_and_err {
    my ($callback) = @_;
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
