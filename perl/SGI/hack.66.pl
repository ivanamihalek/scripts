#! /usr/gnu/bin/perl -w 


$file1 = "2ctc.1.input";
$file2 = "2ctc.2.input"; 
$outfile = "ffff";
open ( FILE1, "<$file1") 
|| die "open fail $file1"; 
open ( OUTFILE, ">$outfile") 
|| die "open fail $outfile"; 


TOP: while ( $line = <FILE1>) {
   
    if ( $line =~ />\s*(\w*-*\w*)\s*/) { 
	$seqname = $1;
	$seq1 = ""; 
        while ( $line = <FILE1>) {
	    last  if ( $line =~ />/);
	    chomp $line;
	    $seq1 = $seq1.lc($line);
	}
	
        open ( FILE2, "<$file2") 
            || die "open fail $file2";
        while (<FILE2>) {
            last if ( $_ =~ $seqname);
        }

	$seq2 = ""; 
        while (<FILE2>) {
            last if />/;
	    chomp;
	    $seq2 = $seq2.lc($_);
        }
        close FILE2;
         

	if ( $seq1 =~ $seq2 && $seq2 =~ $seq1) {
	    print "$seqname ok \n";
	    print OUTFILE ">$seqname\n";
	    $offset = 0;
	    while  ( defined substr ($seq2,$offset,50) ) {
		print OUTFILE  substr  ($seq2,$offset,50),"\n";
		$offset+=50;
	    }
	} else {
	    print " >>>>> $seqname:\n";
	    print " >>>>> $seq1\n";
	    print " >>>>> $seq2\n";
	}
    }
    redo TOP if ( defined $line and $line =~ />/);
}

  close FILE1; 
