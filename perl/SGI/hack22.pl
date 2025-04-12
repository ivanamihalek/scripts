#! /usr/gnu/bin/perl -w


(defined $ARGV[0]   ) ||
    die "usage: hack22.pl  <pdb_list>  \n.";

$pdblist = $ARGV[0];


open (FAILFILE,">fail\n") ||
    die "cno fail file: $! \n";

open (PDBLIST, "<$pdblist") ||
    die "could not open $pdblist.\n";
while (<PDBLIST>) {

    $no_files++;
    chomp;
    $name = $_;
    $sumfile = "$name/"."$name.psi.2.cluster_report.summary";
    $seqfile = "$name/"."$name.seq";
    if ( open (SUMFILE, "<$sumfile") ) { 

	if ( open ( SEQFILE, "<$seqfile") ) {
	    <SEQFILE>;
	    $seq = "";
	    while ( <SEQFILE> ) {
		chomp;
		$seq .= $_;
	    }
	    @aux = split ('', $seq);
	    $length = $#aux;
	    close SEQFILE;
	    while ( <SUMFILE>) {
		if (/max/) {
		    chomp;
		    @aux = split;
		    if ( $aux[2] > -50) {
			print "$name   $length    $aux[2] \n";
		    }
		
		}
	    }
	    close SUMFILE;
	} else {
	    print FAILFILE "$name\n";
	}
        
    } else {
	print FAILFILE "$name\n";
    }
    
}

close PDBLIST;

close FAILFILE;
