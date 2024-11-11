#! /usr/bin/perl -w
use IO::Handle;         #autoflush

defined $ARGV[0] || 
    die "usage: serial_blast.pl <name_list>\n";

$HOME = "/home/i/imihalek";

$database = "/home/pine/databases/prodom";
$blast   = "$HOME/bin/blast/blastall";
open ( ERRLOG, ">prodom.errlog") ||
    die "Cno errlog:$! \n.";
 

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

$home = `pwd`;
chomp $home;

while ( <NAMES> ) { 
   
    $begin = time;
    chomp;
    $name = $_;
    $name =~ s/\s//g;

    $query     = "$name.seq";
    $blastout  = "$name.prodom";

    print "\n $name:\n"; 
    chdir $home ||
	die "cn chdir $home: $!\n";
    chdir "$name" ||
	 die "cn chdir $name: $!; current dir is: ".`pwd`."\n";

    if ( ! -e $query ) {
	print "$query file not found.\n";
	next;
    }
    print "\t running blast ... \n"; 
    print "\t               writing to $blastout \n"; 
    $evalue =  1.e-30;
    $commandline = "$blast -p blastp -d $database -i $query -o $blastout -e $evalue  -v  40   -b  40 -K 500   -m 8";
    #$commandline = "nice $nice_level  $blast -j $psi_it -d $database -i $query -o $blastout -e 1.0e-40 -b 1000 -K 500 -m 8";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("blast");
	next;
    }
    print "\t                  ... done (", time-$begin, "s)\n"; 


}

close ERRLOG;


sub process_failure  {
    	print ERRLOG "\n$name: $_[0] failure.\n";
	print ERRLOG "\texit value: ", $? >> 8, "\n"; 
	print ERRLOG "\t signal no: ", $? & 127, "\n"; 
	if ( $? & 128 ) {
	    print ERRLOG "\tcore dumped.\n";
	}
}
