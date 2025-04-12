#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: serial_autogrid.pl <name_list>\n";

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

$home = `pwd`;
#$home = "/sycamore/ivana/projects/cow/fssp/chains/";
chomp $home;

while ( <NAMES> ) {
   
    $begin = time;
    chomp;
    @aux = split;
    $name = $aux[0];


    print "\n $name:\n"; 
    chdir $home ||
	die "cn chdir $home: $!\n";
    $proteindir = "proteins/$name";
    chdir  $proteindir ||
	die "cn chdir $proteindir: $!; current dir is: ".`pwd`."\n";

}
