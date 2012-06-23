#! /usr/bin/perl -w


$CUTOFF_DIST = 6.0; 
$CUTOFF_CVG  = 0.1;
$T = 0.01;


if ( ! (defined $ARGV[0] && defined $ARGV[1]  && defined $ARGV[2] ) ) {
    print "\nusage: score_ligand_position.pl   <protein_pdb_name> <ligand_pdb_name> <ranks_sorted_file>.\n\n";
    exit;
}



$pdbfile1 = $ARGV[0];
$pdbfile2 = $ARGV[1];

$ranks_file = $ARGV[2];
$res_column = 1;
$rank_column = 6;
$cvg_column = 7;

open (PDBFILE1, "<$pdbfile1") ||
    die "could not open $pdbfile1.\n";

open (PDBFILE2, "<$pdbfile2") ||
    die "could not open $pdbfile2.\n";

 $prev_aa = 0;
$ctr = 0;
while ( <PDBFILE1> ) {
    next if ( ! /^ATOM/ );
    chomp;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;

    if (  $res_seq != $prev_aa ) {
	if ( $prev_aa  ) {
	    $atom_1_ctr[$prev_aa] = $ctr;
	}
	$ctr = 0;
	$prev_aa = $res_seq;
    }
    $atom_1 [$res_seq][$ctr][0] = $serial;
    $atom_1 [$res_seq][$ctr][1] = $x;
    $atom_1 [$res_seq][$ctr][2] = $y;
    $atom_1 [$res_seq][$ctr][3] = $z;
    $ctr++;
}
$atom_1_ctr[$prev_aa] = $ctr;

$highest_aa_1 = $res_seq;

 $ctr = 0;
while ( <PDBFILE2> ) {
    chomp;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;
    $atom_2 [0][$ctr][0] = $serial;
    $atom_2 [0][$ctr][1] = $x;
    $atom_2 [0][$ctr][2] = $y;
    $atom_2 [0][$ctr][3] = $z;
    $ctr++;
}
$atom_2_ctr[0] = $ctr;

$highest_aa_2 = 0;



#****************************************************************
#****************************************************************

open (RANKS, "<$ranks_file") ||
    die "could not open $ranks_file.\n";
while ( <RANKS> ) {
    next if ( /%/ );
    next if ( ! /\S/ ); # to get rid of empty lines 
    @aux = split;
    if ( $aux[$res_column] !~ '-' ) {
	$rank1[$aux[$res_column]] = $aux[$rank_column] ;
    }
   ( defined $aux[$cvg_column] ) ||
       die "No cvg info in $ranks_file (is it *.ranks_sorted?)\n";
    if ( $aux[$cvg_column] !~ '-' ) {
	$cvg1[$aux[$res_column]] = $aux[$cvg_column] ;
    }
    
}
close RANKS;

#****************************************************************
#****************************************************************


$total_score = 0;
$score2  = 0;
$score3  = 0;
$norm = 0;
$norm_i = 0;
$norm_u = 0;
$important_avg_dist = 0;
$unimportant_avg_dist = 0;
$score_p = 0;
$score_m = 0;

for ( $aa1 =0; $aa1 <= $highest_aa_1 ; $aa1++ ) {
    if ( defined $atom_1_ctr[$aa1]  && $atom_1_ctr[$aa1] > 0 ) {

	for ( $aa2 =0; $aa2 <= $highest_aa_2; $aa2++ ) {
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
			if ( $r < $CUTOFF_DIST) {
			    #printf "%6d %6d %6d   %8.3f  %8.3f  %8.3f \n", 
			    #$aa1, $ctr1,$ctr2, $r, $rank1[$aa1],1.0/($r*$rank1[$aa1]) ;
			    $contact_score  = 1.0/($r*$cvg1[$aa1]);
			    $total_score += $contact_score;
			    $norm ++;
			    $score3 += (1/(1+exp(($cvg1[$aa1]-$CUTOFF_CVG)/$T)) - 0.5)*1.0/($r_min*$rank1[$aa1]);
			}
			if ($r <= $r_min ) {
			    $r_min = $r;
			}
		    }
		}
		($r_min > 0) ||
		    die " distance == 0 (?) ... residues: $aa1 $aa2 \n";
		if ( $r_min < $CUTOFF_DIST) {
		    $weight = (1-exp(($cvg1[$aa1]-$CUTOFF_CVG)/$T))/(1+exp(($cvg1[$aa1]-$CUTOFF_CVG)/$T))/$r_min;
		    if ( $cvg1[$aa1] <= $CUTOFF_CVG ) {
			$important_avg_dist += $r_min; 
			$norm_i++;
			$score_p += $weight;
		    } else {
			$unimportant_avg_dist += $r_min;
			$norm_u ++;
			$score_m += $weight;
		    }
		    $norm ++;
		    $score2 += $weight;
		} 
	    }

	}
	
    }
}

$ligand_size = $atom_2_ctr[0];
if ( $ligand_size) {
} else {
    die "No ligand?.\n";
}

if ( $norm) {
    $total_score /= $norm;
} else {
    die "No contacts?.\n";
}
if ( $norm_i) {
    $important_avg_dist  /= $norm_i;
    $score_p /=  $norm_i;
}
if ( $norm_u) {
    $unimportant_avg_dist  /= $norm_u;
    $score_m /=  $norm_u;
}
printf " %10.4e   %10.4e   %10.4e   %10.4e   %10.4e \n",
    $total_score, $important_avg_dist, $unimportant_avg_dist,
     $unimportant_avg_dist -  $important_avg_dist, $score_p+$score_m;
