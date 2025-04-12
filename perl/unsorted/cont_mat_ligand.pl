#! /usr/bin/perl -w


(defined $ARGV[0] && defined $ARGV[1]  ) ||
    die "usage: cont_mat.pl  <protein_pdb_name> <ligand_pdb_name> <ranks_file>\n.";

$pdbfile1 = $ARGV[0];
$pdbfile2 = $ARGV[1];

$ranks_file = $ARGV[0].".ranks";
$res_column = 1;
$rank_column = 3;
$aa_col = 5;

open (PDBFILE1, "<$pdbfile1") ||
    die "could not open $pdbfile1.\n";

open (PDBFILE2, "<$pdbfile2") ||
    die "could not open $pdbfile2.\n";

$prev_aa = 0; $ctr = 0;
while ( <PDBFILE1> ) {
    chomp;
    @aux = split;
    if ( $aux[$aa_col] != $prev_aa ) {
	$atom_1_ctr[$prev_aa] = $ctr;
	$ctr = 0;
	$prev_aa = $aux[$aa_col];
    }
    $atom_1 [$aux[$aa_col]][$ctr][0] = $aux[1];
    $atom_1 [$aux[$aa_col]][$ctr][1] = $aux[$aa_col+1];
    $atom_1 [$aux[$aa_col]][$ctr][2] = $aux[$aa_col+2];
    $atom_1 [$aux[$aa_col]][$ctr][3] = $aux[$aa_col+3];
    $ctr++;
}
$atom_1_ctr[$prev_aa] = $ctr;

$highest_aa_1 = $aux[$aa_col];

$aa_col = 4;
 $ctr = 0;
while ( <PDBFILE2> ) {
    chomp;
    @aux = split;
    $atom_2 [0][$ctr][0] = $aux[1];
    $atom_2 [0][$ctr][1] = $aux[$aa_col+1];
    $atom_2 [0][$ctr][2] = $aux[$aa_col+2];
    $atom_2 [0][$ctr][3] = $aux[$aa_col+3];
    $ctr++;
}
$atom_2_ctr[0] = $ctr;

$highest_aa_2 = 0;

#****************************************************************

open (RANKS, "<$ranks_file") ||
    die "could not open $ranks_file.\n";
while ( <RANKS> ) {
    next if ( /%/ );
    if ( /\d/ ) { # to get rid of empty lines 
	@aux = split;
	if ( $aux[$res_column] !~ '-' ) {
	    $rank1[$aux[$res_column]] = $aux[$rank_column] ;
	}
    }
}
close RANKS;




for ( $aa1 =0; $aa1 <= $highest_aa_1 ; $aa1++ ) {
    if ( defined $atom_1_ctr[$aa1]  && $atom_1_ctr[$aa1] > 0 ) {

AA2:	for ( $aa2 =0; $aa2 <= $highest_aa_2; $aa2++ ) {
	    if ( defined $atom_2_ctr[$aa2]  && $atom_2_ctr[$aa2] > 0 ) {
		$r_min = 1000.0;
		for ($ctr1=0; $ctr1<$atom_1_ctr[$aa1]; $ctr1++) {
		    $x1 = $atom_1[$aa1][$ctr1][1];
		    $y1 = $atom_1[$aa1][$ctr1][2];
		    $z1 = $atom_1[$aa1][$ctr1][3];

		    for ($ctr2=0; $ctr2<$atom_2_ctr[$aa2]; $ctr2++) {
			$x2 = $atom_2[$aa2][$ctr2][1];
			$y2 = $atom_2[$aa2][$ctr2][2];
			$z2 = $atom_2[$aa2][$ctr2][3];
			
			$r = ($x1-$x2)*($x1-$x2)+ ($y1-$y2)*($y1-$y2)
			    +($z1-$z2)*($z1-$z2);
			$r = sqrt ($r);
			if ($r <= $r_min ) {
			    $r_min = $r;
			}
		    }
		}
	        ($r_min > 0) ||
		    die " distance == 0 (?) ... residues: $aa1 $aa2 \n";
		$cookout = exp ($r_min/3.0);
		$contact_score = 1000.0/($cookout*$rank1[$aa1]);
		printf ("%6d %6d %8.3f  %6d %8.3f \n", 
			$aa1, $aa2, $r_min, $rank1[$aa1], $contact_score);
	    }
	}
	
    }
}
