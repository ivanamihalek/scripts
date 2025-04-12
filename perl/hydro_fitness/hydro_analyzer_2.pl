#! /usr/bin/perl -w 

# combine hydro fitness and clustering score analysis

use IO::Handle;

$pdbnames = "used.list";
$path = "/sycamore/folding_data/dd/multiple/";
$results_path = "/sycamore/folding_data/trace/decoy/";
$my_results = "/home/protean5/imihalek/projects/cow/decoys/dd/multiple/";

@sets = ("4state_reduced/", "fisa/",  "fisa_casp3/",  "hg_structal/",  
	 "lattice_ssfit/", "lmds/", "lmds_v2/");

%polarity = ("CYS","H", "PHE","H", "ILE", "H", "LEU", "H", 
	     "MET","H", "VAL", "H", "TRP", "H");
$r_cutoff = 7.3;
$R_cutoff = 10;

open (FH, "<$pdbnames" ) || 
    die "Cno $pdbnames: $! \n"; 


open (OF, ">hydro_all") ||
    die "Cno hydro_all: $! \n"; 

$home = `pwd`;

TOP: while ( <FH> ) { 
    next if  ( ! (/\w/));
    chomp;
    @aux = split ('', $_);
    $name_native = $_;
    if ( $#aux == 3) {
	$name = $_;
    } else {
	$name = join ('', @aux[0..3])."-"."$aux[$#aux]";
    }
    $ok = 0;
    SET: for  $set (@sets) {
	
	$full = $path.$set.$name;
	if ( -e $full ) {
	    $ok = 1;
	    print "$name_native belongs to  $set.\n";
	    $full = $my_results.$name_native;
	    open ( NOC, "<$full/noc2") ||
		die "Cno $full/noc2: $! \n"; 
	    open ( OF, ">$full/all_scores.all_ranks.2") ||
		die "Cno $full/all_scores.all_ranks.2: $! \n"; 
	    for $j (1..6) {
		for  $i (0..1500) {
		    $bin[$j][$i] = 0;
		}
		$total[$j] = 0;
		$perc[$j][0]  = $perc[$j][1]  = $perc[$j][2]  = $perc[$j][3]  = 0;
	    }

	    while ( <NOC> ) {
		chomp;
		($current_name, $dist, $noc)  = split;
		$full = $path.$set.$name;
		$full2 = $full."/".$current_name;
		
		find_hydro_score ( $full2 );
		$aux_name = substr $current_name, 0, (length $current_name) - 4;
		$auxstr =   $aux_name;
		$auxstr =~ s/\-//g;
		if ( $name_native =~ $auxstr ) {
		    $aux_name = $auxstr;
		}
		$sum_name = $results_path."$name_native/$aux_name.zs.psi.ars.cluster_report.summary";
		( -e $sum_name ) ||
		    die "could not find $sum_name (curent: $current_name).\n";
	
		@aux =
		    split ' ', `tail -2  $sum_name | head -1`;
		($zs, $za, $zsa) = @aux[2..4];
		open ( SUMF, "<$sum_name" ) ||
		    die "Cno $sum_name: $!.\n";
		while ( <SUMF> )  {
		    next if ( !/\w/ || /Trace/ || /Rank/);
		    last if ( /total/ );
		    @aux = split;
		    if ( $zs   == $aux[5] ) {
			$za   = $aux[6];
			$zsa  = $aux[7];
			last;
		    }
		}
		close SUMF;
		printf OF  "%-40s  %8.3f  %8d     %8.3f   %8.3f %8.3f %8.3f \n",
		$current_name, $dist, $noc, $score, $zs, $za, $zsa;
	    }	   
	    close NOC;
	    close OF,
	    last SET; 
	}
    }
    if ( ! $ok ) {
	print "\t\t $name not found \n";
    }
}
closeFH;


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
    }
    $score = $totb*$toth/($hydro**2);
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
