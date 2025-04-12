#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: serial_fetch.pl <name_list>\n";



open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

$home = `pwd`;
chomp $home;

while ( <NAMES> ) {
   
    $begin = time;
    chomp;
    @aux = split;
    $name = $aux[0];


    chdir $home ||
	die "cn chdir $home: $!\n";
    chdir $name ||
	die "cn chdir $name: $!; current dir is: ".`pwd`."\n";

    $gifile = "$name.gi";
    $retval = `short_fetch.pl $gifile >  short_entrez`;
    print $retval;
 
}
