#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
sub 	process_entry;


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
#  reading the input
$ok_ctr = 0;
$entry = "";
while ( <> ) {
    if ( /^\/\// ) {
	process_entry ();
	$entry = "";
    } else {
	$entry .= $_;
    }
    
}

print "\nno usable cases: $ok_ctr\n\n";

foreach $key ( keys %pair_ctr ) {
    if ( $pair_ctr{$key} ) {
	print "$key    $pair_ctr{$key}\n";
    }
}

print "\n\n\n";

foreach $key ( keys %aa_pair_ctr ) {
    if ( $aa_pair_ctr{$key} ) {
	print "$key    $aa_pair_ctr{$key}\n";
    }
}



######################################################
#  actual parsing
sub 	process_entry  () {
    @lines = split '\n', $entry;
    foreach $line ( @lines ) {
	if ( $line =~ /^PID/ ) {
	    ($field, $pid) = split ' ', $line;
	} elsif ( $line =~ /^AID/ ) {
	    ($field, $avgid) = split ' ', $line;
	} elsif  ( $line =~ /^DNO/ ) {
	    ($field, $no_dna) = split ' ', $line;
	    last;
	}
    }
    if ( $avgid >= 0.8 && $no_dna >2  ) { 
	$ok_ctr ++;
	printf " %-20s   %8.3f   %5d  %5d\n", $pid, $avgid, $no_dna, $ok_ctr;
    } else {
	return;
    }
    $seq_ctr = 0;
    $aseq_ctr = 0;
    foreach $line ( @lines ) {
	if ( $line =~ /^ASQ/ ) {
	    ($field, $aseq) = split ' ', $line;
	    $aseqs [$aseq_ctr] = $aseq;
	    $aseq_ctr ++;

	} elsif ( $line =~ /^DSQ/ ) {
	    ($field, $seq) = split ' ', $line;
	    $seqs [$seq_ctr] = $seq;
	    $seq_ctr ++;

	}
    }
    print "\t no seq: $seq_ctr  $aseq_ctr  \n";
    $num_seq = $seq_ctr;


    $length = length ($seqs [0]);
    for $seqctr1 ( 0 .. $num_seq-2) {
	$seq1 = $seqs[$seqctr1];
	for $seqctr2 ( $seqctr1+1 .. $num_seq-1) {
	    $seq2 = $seqs[$seqctr2];
	    for ($codon_ctr = 0; $codon_ctr<$length; $codon_ctr+=3 ) {
		$codon1 = substr $seq1, $codon_ctr, 3;
		$codon2 = substr $seq2, $codon_ctr, 3;
		$pair_ctr {$codon1." ".$codon2} ++;
	    }
	}
    }

    $num_seq = $aseq_ctr;
    $length = length ($aseqs [0]);
    for $aseqctr1 ( 0 .. $num_seq-2) {
	$aseq1 = $aseqs[$aseqctr1];
	for $aseqctr2 ( $aseqctr1+1 .. $num_seq-1) {
	    $aseq2 = $aseqs[$aseqctr2];
	    for ($aa_ctr = 0; $aa_ctr<$length; $aa_ctr+=1 ) {
		$aa1 = substr $aseq1, $aa_ctr, 1;
		$aa2 = substr $aseq2, $aa_ctr, 1;
		$aa_pair_ctr {$aa1." ".$aa2} ++;
	    }
	}
    }

}
