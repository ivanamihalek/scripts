#! /usr/gnu/bin/perl -w


use Simple;		#HTML support

$ENTRYDIR =  "epitope_literature";
$ENTRYIDSFILE = "lit_entries";

if ( ! -e "$ENTRYDIR") {
    mkdir ("$ENTRYDIR", 0770) ||
	die "Cannot make $ENTRYDIR directory .\n";
}

open (ENTRYIDS,"<$ENTRYIDSFILE" ) ||
    die "Could not open $ENTRYIDSFILE\n";

while ( <ENTRYIDS>) {
    chomp;
    @entry_ids = split;
    foreach $entry_id ( @entry_ids [2.. $#entry_ids] ){
	$entry_id =~ s/\s//g; # get rid of whitespace
	next if ( defined $found{$entry_id} );
	$found{$entry_id} = 1;
	print $entry_id, " \n"; 
	$entryfile = get "http://spock.genes.nig.ac.jp/~pmd/cgi-bin/PMD/PMDseqen.pl.cgi?$entry_id"
	|| "";
	if ( $entryfile ) {
	    open ( ENTRYFILE, ">$ENTRYDIR/$entry_id") ||
		die "could not open $entry_id\n";
	    $entryfile =~ s/\<.+\>//g;
	    print ENTRYFILE  $entryfile;
	    close ENTRYFILE;
	    print "wrote $entry_id\n";
	} else {
	    print "$entry_id retrieval failure.\n";
	}
    }
			
}

close ENTRYIDS;
