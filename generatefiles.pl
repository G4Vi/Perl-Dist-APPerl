#!/usr/bin/perl
open(my $fh, '<', 'filelist.txt');
my $prefix = '"$PREFIX_NOZIP"';
my $cmd = "";
my $partcmd = "";
while(my $file = <$fh>) {
    chomp $file;
    $partcmd .= "$prefix$file ";
    if(length $partcmd > 1000) {
        $cmd .= "$partcmd\\\n";
        $partcmd = '';
    }
}
$cmd .= $partcmd;
chop $cmd;
print "$cmd\n";