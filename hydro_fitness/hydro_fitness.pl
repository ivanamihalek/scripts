#! /usr/bin/perl -w 
use IO::Handle;

(defined $ARGV[0]) ||
    die "Usage: hydro_fitness.pl <pdb_name>.\n"; 
%polarity = ("CYS","H", "PHE","H", "ILE", "H", "LEU", "H", 
	     "MET","H", "VAL", "H", "TRP", "H");
$r_cutoff = 7.3;
$R_cutoff = 10;
$score = 0;
$name =  $ARGV[0];

find_hydro_score ( "$name/$name.pdb");
printf "the score is %8.3f .\n", $score;


sub find_hydro_score { # "hydrophobic fitness"
    $pdbfile = $_[0];
    open (PDBFILE, "<$pdbfile") ||
	die "could not open $pdbfile.\n";

    undef $lowest_aa;
    $prev_aa = -7; $ctr = -1;
    $prev_name = "";
    while ( <PDBFILE> ) {
	if ( /^ATOM/ ) {
	    chomp;
	    @aux = split '';
	    $res_number = join ('', @aux[22..25]);
	    $res_name   = join ('', @aux[17..19]);
	    if (! defined $lowest_aa ) {
		$lowest_aa = $res_number;
	    }
	    if ($res_number != $prev_aa ) {
		process_aa();
		$ctr = 0;
		$prev_aa =  $res_number;
		$prev_name = $res_name;
		for $i ( 0, 1,2 ) {
		    $ca[$i] = $cb[$i] = 0;
		}
	    }
	    $x =  join ('', @aux[30..37]);
	    $y =  join ('', @aux[38..45]);
	    $z =  join ('', @aux[46..53]);
	    $atom_name = join ('', @aux[13..14]) ;
	    if ( "CA" =~ $atom_name ) {
		$ctr +=1;
		$ca[0] += $x;
		$ca[1] += $y;
		$ca[2] += $z;
	    }
	    if ( "CB" =~ $atom_name ) {
		$ctr +=2;
		$cb[0] += $x;
		$cb[1] += $y;
		$cb[2] += $z;
	    }
	   
	}
    }
    
    process_aa();

    close PDBFILE;

    $highest_aa = $res_number;

=pod
    for ( $aa1 = $lowest_aa; $aa1 <= $highest_aa ; $aa1++ ) {

	printf " %4d:  %d  %d   %8.3f   %8.3f   %8.3f  \n",
	$aa1,  $hydrophobic[$aa1],   $tyro[$aa1], $centroid[$aa1][0] , $centroid[$aa1][1] ,  $centroid[$aa1][2];
    }
    exit();
=cut

    $hydro_w_tyro = 0;
    $hydro = 0;
    $total = 0;
    for ( $aa1 = $lowest_aa; $aa1 <= $highest_aa ; $aa1++ ) {
	$total ++;
	$no_neighbors[$aa1] = 0;
	if (  $tyro[$aa1] ) {
	    $hydro_w_tyro  ++;
	}
	if ( $hydrophobic[$aa1]) {
	    $hydro ++;
	    $hydro_w_tyro ++;
	    $b[$aa1] = $h[$aa1] = $no_neighbors[$aa1] = 0;
	    for ( $aa2 = $lowest_aa; $aa2 <= $highest_aa; $aa2++ ) {
		next if (  abs($aa1- $aa2) < 2 ); 
		$x = $centroid[$aa1][0] - $centroid[$aa2][0];
		$y = $centroid[$aa1][1] - $centroid[$aa2][1];
		$z = $centroid[$aa1][2] - $centroid[$aa2][2];
		$r = sqrt ($x**2 + $y**2 + $z**2);
		if ( $r <= $R_cutoff ) {
		    $b[$aa1] ++;
		}
		if ($r <= $r_cutoff ){
		    $no_neighbors[$aa1]++;
		    if ($hydrophobic[$aa2] || $tyro[$aa2] ) {
		      $h[$aa1] ++;
		  }
	      }
	      
	    }
	}
    } 
    $score = 0;
    $totb = 0;
    $toth = 0;
    for ( $aa1 = $lowest_aa; $aa1 <= $highest_aa ; $aa1++ ) {
	next if (!  $hydrophobic[$aa1]);
	$t = $total-1;
	$h_fraction = $hydro_w_tyro-1;

	if ( $aa1 > $lowest_aa) {
	    $t--;
	    if ( $hydrophobic [$aa1-1] || $tyro[$aa1-1]) {
		$h_fraction --;
	    }
	}
	if ( $aa1 < $highest_aa ) {
	    $t--;
	    if ($hydrophobic [$aa1+1] || $tyro[$aa1+1] ) {
		$h_fraction --;
	    }
	}

	$h_fraction /= $t;
	$h_exp =  $h_fraction*$no_neighbors[$aa1]; 
	$totb += $b[$aa1]; 
	$toth  += ($h[$aa1]-$h_exp); 
	printf "aa:%5d    hydro:%1d  TYR:%1d     burial:%3d     any nbrs:%3d    hydro nbrs:%3d   Ni:%4d   exp:%7.3f    h-hexp:%7.3f\n",
	$aa1, $hydrophobic[$aa1], $tyro[$aa1], $b[$aa1], $no_neighbors[$aa1], $h[$aa1], $t, $h_exp,  $h[$aa1]-$h_exp, ;
    }
    $score = $totb*$toth/($hydro**2);
    print " totb:      $totb \n";
    print " toth:      $toth\n";
    print " hydro:     $hydro\n";
}

sub process_aa() {
    ($ctr != -1 ) || return;
    ( $ctr != 0 ) || die "Error: no coords found for aa $prev_aa.\n";
    ( $ctr != 2 ) || die "Error: no Calpha  found for aa $prev_aa.\n";

    if ( defined $polarity{$prev_name} ) {
	$hydrophobic  [$prev_aa] = 1;
    } else {
	$hydrophobic  [$prev_aa] = 0;
    }
    if ( $prev_name =~ "TYR" ) {
	$tyro  [$prev_aa]  = 1;
    } else {
	$tyro  [$prev_aa]  = 0;
    }

    $norm = 0;
    for $i ( 0, 1, 2 ) {
	$norm += ($ca[$i]- $cb[$i])**2;
    }
    $norm = sqrt ($norm);
    if ( $ctr == 1 ) { 
	if ( $prev_name !~ "GLY" ) {
	    print " No Cbeta  found for aa $prev_aa.\n";
	}
	for $i ( 0,1,2 ) {
	    $centroid[$prev_aa][$i] = $ca[$i];
	}
    } else {
	for $i ( 0,1,2 ) {
	    $centroid[$prev_aa][$i] = $ca[$i] + ($cb[$i]- $ca[$i])*3/$norm;
	}
    }
    
}
