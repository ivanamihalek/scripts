#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$home = `pwd`;
chomp $home;

$report = "/home/i/imihalek/projects/report_maker/modular/report_maker_3.pl";

while ( <> ) {
    chomp;
    @aux = split;
    $name = $aux[0];
    chdir  $home;
    ( -e $name ) || (mkdir $name);
    chdir $name;

    print $name;
    print "\n";
    #next if ( -e "texfiles/report.pdf");

    $cmd = "$report $name | tee report_maker.log";
    ( system $cmd);
    
} 
