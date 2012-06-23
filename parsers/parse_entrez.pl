#! /usr/gnu/bin/perl -w 
# 1) start with a list of gi's (produced by retrieve.pl)
# 2) do batch download of protein entries from Entrez
# 3) pipe it all as one file through this
# 4) this will produce a table in the form 
#        [gi]  [tax name (shortened)]  [single string descriptor]
#    descriptor length is set in the variable $DESCR_LENGTH below
#    the table is piped directly to stdout
# 5) use that table as an input to gi2name.pl
$DESCR_LENGTH = 50;
$name = "";
$descr = "";
$locus = "";
$gi = 0;


@typical = ("ND1", "ND2", "CO1", "CO2", "AT8", "AT6", "CO3", "ND3", "ND4L", "ND4", "ND5", "ND6", "CB");
foreach $gene ( @typical) {
    open (my $fh, ">$gene.fasta" ) ||
	die "Cno $gene.fasta: $!. \n";
    $handle{$gene} =  $fh;
}

TOP: while ( <> ) {

    if ( /LOCUS/ ) {
	chomp;
	$locus = $_;
	if ( /linear/ ) {
	    $linear = 1;
	} else {
	    $linear = 0; 
	}
    } elsif ( /ORGANISM/ ) {
	chomp;
	$organism =   $_;
	$mismatch =  0;
	@seq = ();
	@aux = split;
	$name = uc (substr $aux[1], 0, 3);
	if ( defined $aux[2] ) {
	   $name .= "_". uc (substr $aux[2], 0, 3);
	}
	$name =~ s/\.//g;

    } elsif (/VERSION/) {
	chomp;
	@aux = split ':';
	$gi = $aux[1];
	
    } elsif (/FEATURES/){
	$ctr = 0;
	$cds = 0;
	$gene = "";
	while ( <> ) {
	    redo TOP  if (/ORIGIN/ || /BASE COUNT/);
	    $keyword = substr $_, 0, 20;
	    if ( $keyword =~ /CDS/ ){
		$ctr ++;
		#chomp;
		#print " $ctr: $_";
		$cds = 1;
	    } elsif ( $keyword =~ /\S/ ) {
		$cds = 0;
	    }
	    if ( $cds ) {
		if ( !$gene && (/gene/ || /note/) && /\"(.+)[\"\n]/ ) {
		    $gene = $1;
		    if ( length $gene < 10 ){
			$gene =~ s/\"//g;
			$gene =~ s/III/3/g;
			$gene =~ s/II/2/g;
			$gene =~ s/I/1/g;
			$gene =~ s/X//ig;
			$gene =~ s/cyt\s*b/Cb/ig;
			$gene =~ s/P//g;
			$gene =~ s/ASE//ig;
			$gene =~ s/[\s-]//g;
			$gene =~ s/NADH/ND/ig;
			$gene = uc $gene;
			if (  $gene  !~ $typical[$ctr-1] ) {
			    $mismatch ++;
=pod
			    print  $locus;
			    print $organism;
			    print "mismatch:  $ctr  $typical[$ctr-1]    ", uc $gene," \n"; 
			    print "\n\n";
=cut
    
			} else {
			    # print "           $ctr  $typical[$ctr-1]    ",  $gene," \n"; 
			}
		    } else {
			$gene = "";
		    }
		} elsif ( /translation/ ) {
		    chmop;
		    $_ =~ /\"(.+)/;
		    
		    $seq{$gene} = $1;
		    while ( <> ) {
			$seq{$gene} .= $_;
			if ( /\"/ ) {
			    $gene = "";
			    last;
			}
		    }
		}
	    }
	  
	}
    } elsif (/BASE_COUNT/){
    } elsif (/ORIGIN/){
	#output 
	if ( $mismatch ) {
	   # print $organism, " ---> mismatch \n";
	} elsif ( $linear ) {
	   # print $organism, " ---> linear \n";
	} else {
	    print $organism, "\n";
	    foreach $gene ( @typical) {
		$seq{$gene} =~ s/\"//g;
		$seq{$gene} =~ s/\s//g;
		$seq{$gene} =~ s/\n//g;
		$fh = $handle{$gene};
		print $fh "> $name \n";
		$l = int ((length $seq{$gene})/50);
		for $i  (0 .. $l-1 ) {
		    print $fh  substr ($seq{$gene}, 50*$i, 50);
		    print  $fh  "\n";
		}
	       
		print $fh  substr ($seq{$gene}, 50*$l, 50);
		print $fh "\n";
	    }
	}
	
    }
    
}



foreach $fh ( %handle) {
    close $fh;
}
