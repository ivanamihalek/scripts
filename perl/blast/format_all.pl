#!/usr/bin/perl -w


@dirs = split "\n", `ls`;

$home = `pwd`;
chomp $home;

$fastafile = "";
foreach $dir (@dirs){

    chdir $home;
    chdir $dir;
    print "\n";
    print $dir, "\n";
    
    $fastafile =  `ls *.fa`;
    
    chomp $fastafile;
    print $fastafile;
    print "\n";

    $cmd = "formatdb -i $fastafile -o T";
    system($cmd) && die "error running $cmd\n";
}
