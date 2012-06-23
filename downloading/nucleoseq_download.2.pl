#! /usr/gnu/bin/perl -w -I/home/i/imihalek/perlscr


use Simple;		#HTML support
$home = `pwd`;
chomp $home;

while ( <>) {
    chomp;
    @names = split;
    foreach $name ( @names ){
	chdir $home;
	$blastfile = "$name/$name.blastp"; 
	if ( -e $blastfile ) {
	    chdir "$name";  
	    (  -e "fastafiles"  ) ||
		mkdir "fastafiles";
	    (  -e "dna_fastafiles"  ) ||
		mkdir "dna_fastafiles";
	    $blastfile = "$name.blastp"; 
	    print `ls 	$blastfile`;
	    open (BF, "<$blastfile") ||
		die "Cno $blastfile.\n";
	    while ( <BF> ) {
		@aux = split;
		$idstring  = $aux[1];
		$pid = $aux[2];
		@aux = split '\|', $idstring;
		$try_id  = $aux[3];
		next if ( $try_id =~ "_");
		$try_id =~ s/\.\d//;
		$httpstr  = "http://srs.ebi.ac.uk/srsbin/cgi-bin/";
		$httpstr .= "wgetz?-e+[EMBL-ProteinID:".$try_id."*]";
		$retfile = get $httpstr	|| "";
		if ( $retfile && $retfile !~ "No entries found") { 
		    print "$pid   $try_id\n";
		    @lines = split '\n', $retfile;
		    $reading = 0;
		    $filename = "fastafiles/$try_id.fasta";
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

		    $filename = "dna_fastafiles/$try_id.fasta";
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
		    
		}
	    }
	    close BF;
	} else {
	    #print "$blastfile dne.\n";
	}
    }
}
