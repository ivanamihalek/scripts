#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);


$process_codons = 0; # i.e. process amino acids instead

#####################################################
#  initialize  codon count
@nts = ("A", "C", "G", "T" ); 
@codons = ();
for $nt1 ( @nts) {
    for $nt2 ( @nts) {
	for $nt3 ( @nts) {
	    $codon = $nt1.$nt2.$nt3;
	    push @codons, $codon;
	}
    }
}
push @codons, "---";

%pair_ctr = ();
for $codon1 ( @codons) {
    for $codon2 ( @codons) {
	$pair_ctr {$codon1." ".$codon2} = 0; 
    }
}

#####################################################
#  initialize  amino acid  count
@aas = ("A", "C", "D", "E", "F", "G", "H", "I", "K", "L", "M", 
	"N", "P", "Q", "R", "S", "T", "V", "W", "Y", "-");
%aa_pair_ctr = ();
for $aa1 ( @aas) {
    for $aa2 ( @aas) {
	$aa_pair_ctr {$aa1." ".$aa2} = 0; 
    }
}


#####################################################
#  input
while ( <> ) {
    last if (/usable/);
}
while ( <> ) {
    next if ( !/\S/ ) ;
    chomp;
    ($codon1, $codon2, $count) = split;
    if ( (length $codon1) == 3 ) { 
	$pair_ctr {$codon1." ".$codon2} = $count;
    } else {
	$aa_pair_ctr {$codon1." ".$codon2} = $count;
    }
}

if ( $process_codons ) {
    #####################################################
    #  process codons
    for $codon_ctr1 ( 0 .. $#codons) {
	$codon1 = $codons[$codon_ctr1];
	for $codon_ctr2 ( $codon_ctr1 + 1 .. $#codons) {
	    $codon2 = $codons[$codon_ctr2];
	    $pair_ctr {$codon1." ".$codon2} += $pair_ctr {$codon2." ".$codon1}; 
	    $pair_ctr {$codon2." ".$codon1}  = $pair_ctr {$codon1." ".$codon2};
	}
    }
    for $codon_ctr1 ( 0 .. $#codons) {
	$codon1 = $codons[$codon_ctr1];
	$sum = 0;
	for $codon_ctr2 ( 0 .. $#codons) {
	    $codon2 = $codons[$codon_ctr2];
	    $sum += $pair_ctr {$codon1." ".$codon2};
	}
	for $codon_ctr2 ( 0 .. $#codons) {
	    $codon2 = $codons[$codon_ctr2];
	    $pair_ctr {$codon1." ".$codon2}/= $sum;
	} 
    }

    #####################################################
    #   codons output
    printf "%8s", " ";
    for $codon_ctr2 ( 0 .. $#codons) {
	$codon2 = $codons[$codon_ctr2];
	printf  "%8s",   $codon2;
    }
    print "\n";
    for $codon_ctr1 ( 0 .. $#codons) { 
	$codon1 = $codons[$codon_ctr1]; 
	printf "%8s", $codon1;
	for $codon_ctr2 ( 0 .. $#codons) { 
	    $codon2 = $codons[$codon_ctr2]; 
	    printf "%8.3f",  $pair_ctr {$codon1." ".$codon2}; 
	}
	print "\n";
    }



} else {
     #####################################################
     #  process aas
    for $aa_ctr1 ( 0 .. $#aas) {
	$aa1 = $aas[$aa_ctr1];
	for $aa_ctr2 ( $aa_ctr1+1 .. $#aas) {
	    $aa2 = $aas[$aa_ctr2];
	    $aa_pair_ctr {$aa1." ".$aa2} += 	$aa_pair_ctr {$aa2." ".$aa1};
	    $aa_pair_ctr {$aa2." ".$aa1} = $aa_pair_ctr {$aa1." ".$aa2};
	}
    }

    for $aa_ctr1 ( 0 .. $#aas) {
	$aa1 = $aas[$aa_ctr1];
	$sum = 0;
	for $aa_ctr2 ( 0 .. $#aas) {
	    $aa2 = $aas[$aa_ctr2];
	    $sum += $aa_pair_ctr {$aa1." ".$aa2} ;
	}
	for $aa_ctr2 ( 0 .. $#aas) {
	    $aa2 = $aas[$aa_ctr2];
	    $aa_pair_ctr {$aa1." ".$aa2} /= $sum;
	}
    }
    #####################################################
    # aa output
    print "   ";
    for $aa_ctr2 ( 0 .. $#aas) {
	$aa2 = $aas[$aa_ctr2];
	printf  "%8s",   $aa2;
    }
    print "\n";
    for $aa_ctr1 ( 0 .. $#aas) {
	$aa1 = $aas[$aa_ctr1];
	print " $aa1 ";
	for $aa_ctr2 (0 .. $#aas) {
	    $aa2 = $aas[$aa_ctr2];
	    printf  "%8.3f",   $aa_pair_ctr {$aa1." ".$aa2};
	}
	print "\n";
    }
    
}





=pod
## check:
for $codon_ctr1 ( 0 .. $#codons) {
    $codon1 = $codons[$codon_ctr1];
    $sum = 0;
    for $codon_ctr2 ( 0 .. $#codons) {
	$codon2 = $codons[$codon_ctr2];
	$sum += $pair_ctr {$codon2." ".$codon1};
    }
    print "  $codon1     $sum  \n";
    
}
=cut
