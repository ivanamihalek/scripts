#! /usr/bin/perl -w
# Ivana, Dec 2001
# make pdbfiles directory  and download the pdbfiles
# for proteins with names piped in


use Simple;		#HTML support

$FSSPDIR =  "fsspfiles";
$FSSPNAMESFILE = "fsspnames";

if ( ! -e "$FSSPDIR") {
    mkdir ("$FSSPDIR", 0770) ||
	die "Cannot make $FSSPDIR directory .\n";
}

open (FSSPNAMES,"<$FSSPNAMESFILE" ) ||
    die "Could not open $FSSPNAMESFILE\n";

while ( <FSSPNAMES>) {
    chomp;
    @fsspnames = split;
    foreach $fsspname ( @fsspnames ){
	@aux  = split ('\.', $fsspname); # get rid of extension
	$fsspname =  $aux[0];
	print $fsspname, " \n"; 
	$fsspfile = get "http://goyder.ebi.ac.uk:8181/cgi-bin/qz?filename=/ebi/msd/dali-data/fssp/$fsspname.fssp"
	|| "";
	if ( $fsspfile ) {
	    open ( FSSPFILE, ">$FSSPDIR/$fsspname.fssp") ||
		die "could not open $fsspname.fssp\n";
	    print FSSPFILE  $fsspfile;
	    close FSSPFILE;
	    print "wrote $fsspname.fssp\n";
	} else {
	    print "$fsspname retrieval failure.\n";
	}
    }
			
}

close FSSPNAMES;
