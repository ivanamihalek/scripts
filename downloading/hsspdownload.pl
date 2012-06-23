#!/usr/bin/perl  -I/home/i/imihalek/perlscr

use Simple;	
$HSSPHOME = "/home/pine/hsspfiles";


$PDBNAMESFILE = "pdbnames";
defined $ARGV[0] && ($PDBNAMESFILE = $ARGV[0]);

open (PDBNAMES,"<$PDBNAMESFILE" ) ||
    die "Could not open $PDBNAMESFILE\n";

while (<PDBNAMES>) {
    chomp;
    if(/^(\w\w\w\w)/) {
	@name = (@name,$1);   
    }
}
close PDBNAMES;

( -e $HSSPHOME ) || die "$HSPPHOME not found.\n";


foreach $search (@name) {
 
    $search = lc $search;
    if (-e  "$HSSPHOME/$search.hssp") {
	print "$search.hssp found in $HSSPHOME.\n";
	next;
    }
    print "$search\n";

    #$hssp = get "ftp://ftp.embl-heidelberg.de/pub/databases/protein_extras/hssp/$search.hssp" || "";
    $hssp = get "ftp://ftp.cmbi.kun.nl/pub/molbio/data/hssp/$search.hssp" || "";
  
    if ( $hssp ) {
	open ( HSSPFILE, ">$HSSPHOME/$search.hssp") ||  
	    die "Error opening $HSSPHOME/$search.hssp: $!.\n";
	print HSSPFILE  $hssp;
	close HSSPFILE;
    } else {
	print "$pdbname retrieval failure.\n";
    }
}

