#! /usr/gnu/bin/perl -w -I/home/i/imihalek/perlscr
# Ivana, Dec 2001
# make pdbfiles directory  and download the pdbfiles
# for proteins with names piped in

#input swissprot id and download nucleotide seq

use Simple;		#HTML support


while ( <>) {
    chomp;
    @names = split;
    foreach $name ( @names ){
	print $name, "\n";
	$retfile = get "http://us.expasy.org/cgi-bin/niceprot.pl?$name"	|| "";
	if ( $retfile ) { 
	    print "found $name in swissprot.\n";
	    $retfile =~ /\[\<a href=\"http\:\/\/srs.ebi.ac.uk\/srsbin\/cgi-bin\/wgetz\?\-e\+\[EMBL-ProteinID\:(.+?)\*\]\"\>CoDingSequence\<\/a>\]/;
	    if ( defined $1 ) {
		print "$1\n";
		$newname = $1;
	    } else {
		    print "reference to CoDing not found.\n";
		next;
	    }
	} else {
	    print "$name not found in swissprot.\n";
	    next;
	} 
	$httpstr = "http://srs.ebi.ac.uk/srsbin/cgi-bin/wgetz?-e+[EMBL-ProteinID:".$newname."*]";
	$retfile = get $httpstr	|| "";
	if ( $retfile ) { 
	    print "found $newname in CoDing.\n";
	    $retfile =~ s/\<.+?\>/ /g;
	    @lines = split '\n', $retfile;
	    $reading = 0;
	    $filename = "$name.aa.fasta";
	    open ( OF, ">$filename" ) ||
		die "Cno $filename.\n"; 
	    print OF "> $name\n";
	    $ctr = 0;
	    TOP: foreach $line ( @lines) { 
		if ( $reading ) {
		    last if ( $line =~ /^SQ/ ); 
		    $line =~ s/\"//g; 
		    $line =~ s/\=//g; 
		    $line =~ s/\/translation//g;
		    $line = substr ($line, 21);
		    print OF  "$line\n"; 
		    $ctr += ($line =~ s/\w//g);
		}elsif ( $line =~ /\/translation/ ) { 
		    $reading = 1; 
		    redo TOP; 
		} 
	    } 
	    close OF;
	    $length_aa = $ctr;
	    print "wrote $filename; sequence length: $length_aa.\n";

	    $filename = "$name.nt.fasta";
	    open ( OF, ">$filename" ) ||
		die "Cno $filename.\n"; 
	    print OF "> $name\n";
	    $ctr = 0;

	    foreach $line ( @lines) {
		next if ( $line !~ /\S/ );
		next if ( substr ($line, 0, 2) =~ /\S/ );
		$line = substr ($line,0, 70);
		print OF  "$line\n";
		$ctr += ($line =~ s/\w//g);
	    }
	    close OF;
	    $length_nt = $ctr;
	    print "wrote $filename; sequence length: $length_nt.\n";
	    #sanity check: is the nt seq 3 times longer than the aa
	    (($length_nt - 3*$length_aa) < 4 ) || 
		print "Warning: sequence lengths do not match.\n";
	} else {
	    print "$newname not found in CoDing.\n";
	}
	
	
    }
			
}

