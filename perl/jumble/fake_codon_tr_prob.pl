#! /usr/bin/perl  


use IO::Handle;         #autoflush
# FH -> autoflush(1);

$AAs  = "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
$Starts = "---M---------------M---------------M----------------------------";
$Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
$Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
$Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

@aas = split '', $AAs;
@starts = split '', $Starts;
@base1 = split '', $Base1;
@base2 = split '', $Base2;
@base3 = split '', $Base3;

for $i (0..$#aas) {
    $codon= $base1[$i]. $base2[$i]. $base3[$i];
    $codon2aa{$codon} = $aas[$i];
    if ( defined $aa2codon{ $aas[$i] } ) {
	$aa2codon{ $aas[$i] } .= " $codon";
    } else {
	$aa2codon{ $aas[$i] }  = "$codon";
    }
}
$codon2aa{"..."} = ".";
$aa2codon{ "."} = {"..."};

foreach $aa( keys %aa2codon ) {
    $codons = $aa2codon{ $aa };
    @aux = split ' ', $codons;
    $multiplicity{$aa} = $#aux+1;
}


printf "%5s", "";
foreach $codon2 ( keys %codon2aa ) {
    printf "%8s", $codon2;
}
printf "\n";

foreach $codon1 ( keys %codon2aa ) {
    $aa1 = $codon2aa{$codon1};
    printf "%5s", $codon1;
    foreach $codon2 ( keys %codon2aa ) {
	$aa2 = $codon2aa{$codon2};
	if ( $aa1  eq $aa2 ) {
	    $prob = 1.0/$multiplicity{$aa1};
	} else {
	    $prob = 0;
	}
	printf "%8.2f", $prob;
    }
    printf "\n";
}
