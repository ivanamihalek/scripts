#! /usr/bin/perl -w 

$CUTOFF_R = 5.0;

(defined $ARGV[0] && defined $ARGV[1]  ) ||
    die "usage: $0  <protein_pdb_file> <ligand_pdb_file> [<cutoff_distance>].\n";

$pdbfile1 = $ARGV[0];
$pdbfile2 = $ARGV[1];
if ( defined $ARGV[2] ) {
    $CUTOFF_R =  $ARGV[2];
}
$inverse = 0;
if ( defined $ARGV[3] ) {
    $inverse = 1;
}

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
    $res_name_1[$res_seq] = substr $_,  17, 3; $res_name_1 [$res_seq]=~ s/\s//g;
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


for ( $aa1 =0; $aa1 <= $highest_aa_1 ; $aa1++ ) {
    if ( defined $atom_1_ctr[$aa1]  && $atom_1_ctr[$aa1] > 0 ) {

	$nearest = 1000;
	for ( $aa2 =0; $aa2 <= $highest_aa_2; $aa2++ ) {
	    if ( defined $atom_2_ctr[$aa2]  && $atom_2_ctr[$aa2] > 0 ) {

		

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

			if ($r <= $CUTOFF_R && $nearest > $r) {
			    $nearest = $r;
			}
		    }
		}


	    }
	}
	if ( $nearest <  1000 ) {
	    printf ("%6d  %8.1f   $res_name_1[$aa1]\n", $aa1, $nearest);
	}
	
    }
}
