#!/usr/bin/perl  -I/home/i/imihalek/perlscr

use Simple;	
$MMOLNAMESFILE = "mmolnames";
if ( defined $ARGV[0] ) {
    $MMOLNAMESFILE =  $ARGV[0];
}

open (MMOLNAMES,"<$MMOLNAMESFILE" ) ||
    die "Could not open $MMOLNAMESFILE\n";
@names = ();
while (<MMOLNAMES>) {
    @aux = split;
    push  @names, $aux[0];  
    
}
close MMOLNAMES;

( -e "mmolfiles"  ) || `mkdir mmolfiles`;

open (FAIL, ">mmolfail") ||
    die "Cno mmolfail: $!.\n";

foreach $search (@names) {
 
    next if (-e "mmolfiles/$search.mmol");
    print "$search\n";

    $mmol = get "ftp://ftp.ebi.ac.uk/pub/databases/msd/pqs/macmol/$search.mmol" || "";
  
    if ( $mmol ) {
	open ( MMOLFILE, ">mmolfiles/$search.mmol") ||  
	    die "Error opening mmolfiles/$search.mmol: $!.\n";
	print MMOLFILE  $mmol;
	close MMOLFILE;
    } else {
	print "$mmolname retrieval failure \n";
	print OFrasmol mmole\n"
    }
}

close OF
