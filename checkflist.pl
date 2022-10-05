#!/usr/bin/perl
open(my $fh, '<', 'filelist.txt');

chdir($ENV{HOME}."/.config/apperl/o/small/tmp/zip") or die "failure $!";
while(my $file = <$fh>) {
    chomp $file;
    if( ! -f $file) {
        my $ogfile = $file;
        $file =~ s/5\.36\.0/5.36.0\/x86_64-cosmo/;
        if(-f "$file") {
            print "$file\n";
        }
        else {
            print "missing $ogfile\n";
        }
    }
}
