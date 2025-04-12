#! /usr/bin/perl -w 

# combine hydro fitness and clusterin score analysis

use IO::Handle;

$pdbnames = "tmp.list";
$path = "/sycamore/folding_data/dd/multiple/";
$results_path = "/sycamore/folding_data/trace/decoy/";
$my_results = "/home/protean5/imihalek/projects/cow/decoys/dd/multiple/";

@sets = ("4state_reduced/", "fisa/",  "fisa_casp3/",  "hg_structal/",  
	 "lattice_ssfit/", "lmds/", "lmds_v2/");

%polarity = ("CYS","H", "PHE","H", "ILE", "H", "LEU", "H", 
	     "MET","H", "VAL", "H", "TRP", "H");
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
	    print "$name_native belongs to  $set.\n";
	    $full = $my_results.$name_native;
	    open ( NOC, "<$full/noc2") ||
		die "Cno $full/noc2: $! \n"; 
	    for $j (1..6) {
		for  $i (0..1500) {
		    $bin[$j][$i] = 0;
		}
		$total[$j] = 0;
		$perc[$j][0]  = $perc[$j][1]  = $perc[$j][2]  = $perc[$j][3]  = 0;
	    }
	    while ( <NOC> ) {
		chomp;
		@aux = split;
		$full = $path.$set.$name;
		$full2 = $full."/".$aux[0];
		$current_name = $aux[0];
		$noc = $aux[2];
		if ( $current_name =~ "$name.pdb" ) {
		    printf OF  "$current_name: noc in native: $noc\n"; 
		    printf  "$current_name: noc in native: $noc\n"; 
		    OF -> autoflush(1);
		    $noc_native = $noc;
		    find_hydro_score ( $full2 );
		    printf OF "native hydro score: %8.3f\n", $score; 
		    printf   "native hydro score: %8.3f\n\n", $score; 
		    $native_score = $score;
		    $sum_name = $results_path."$name_native/$name_native.zs.psi.cluster_report.summary";
		    @aux =
			split ' ', `tail -2  $sum_name | head -1`;
		    ($zs_native, $za_native, $zsa_native) = @aux[2..4];
		    last;
		}
	    }
	    seek NOC, 0, 0; # this is rewinding

	    while ( <NOC> ) {
		chomp;
		($current_name, $dist, $noc)  = split;
		next if ( "$name.pdb" =~  $current_name);
		$full = $path.$set.$name;
		$full2 = $full."/".$current_name;
		
		find_hydro_score ( $full2 );
		if ( $dist < 5.0 ) {
		    process_bin (1);
		} elsif ( $dist < 7.5) {
		    process_bin (2);
		} elsif ( $dist < 10.0) {
		    process_bin (3);
		} elsif ( $dist < 12.5) {
		    process_bin (4);
		} elsif ( $dist < 15.0) {
		    process_bin (5);
		} else {
		    process_bin (6);
		}
	    }
	    close RMS;
	    $ok = 1;
	    for $i (1..6) {
		if ( $total[$i] ) {
		    if (  $perc [$i][0] ) {
			for $j (1 .. 1) {
			    $perc [$i][$j] /= $perc [$i][0];
			}
		    } else {
			for $j (1 .. 1) {
			    $perc [$i][$j] = -1;
			}
		    }
		    $perc [$i][0] /= $total[$i];
		    $perc [$i][2] /= $total[$i];
		} else {
		    $perc [$i][0]  = $perc[$i][1] = -1;
		}
		printf OF " %2d  %5d   %8.3lf    %8.3lf  %8.3lf    ", 
		$i,  $total[$i],  $perc [$i][0], $perc [$i][1], $perc [$i][2] ;
		OF -> autoflush(1);
		print OF "\n";
	    }
	    print OF "\n";
	    OF -> autoflush(1);
	    last SET; 
	}
    }
    if ( ! $ok ) {
	print "\t\t $name not found \n";
    }
}
closeFH;



sub find_hydro_score { # "hydrophobic fitness"
    $r_cutoff = 5;
    $pdbfile = $_[0];
    open (PDBFILE, "<$pdbfile") ||
	die "could not open $pdbfile.\n";

    undef $lowest_aa;
    $prev_aa = 0; $ctr = 0;
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
		$ctr -= 3;
		if ( $ctr ) {
		    if ( defined $polarity{$res_name} ) {
			$hydrophobic  [$prev_aa] = 1;
		    } else {
			$hydrophobic  [$prev_aa] = 0;
		    }
		    if ( $res_name =~ "TYR" ) {
			$tyro  [$prev_aa]  = 1;
		    } else {
			$tyro  [$prev_aa]  = 0;
		    }
		    $centroid_x [$prev_aa] = $avg_x/$ctr;
		    $centroid_y [$prev_aa] = $avg_y/$ctr;
		    $centroid_z [$prev_aa] = $avg_z/$ctr;
		}
		$prev_aa =  $res_number;
		$ctr     = 0;
		$avg_x   = 0;
		$avg_y   = 0;
		$avg_z   = 0;
	    }
	    $atom_number = join ('', @aux[6..10]) ;
	    $x =  join ('', @aux[30..37]);
	    $y =  join ('', @aux[38..45]);
	    $z =  join ('', @aux[46..53]);
	   
	    $ctr++;
	    if ( $ctr==2 || $ctr > 4 ) { # sidechain, using C-alpha
		$avg_x += $x;
		$avg_y += $y;
		$avg_z += $z;
		
	    }
	}
    }
    if ( $ctr ) {
	$no_of_atoms[$prev_aa] = $ctr;
	if ( defined $polarity{$res_name} ) {
	    $hydrophobic  [$prev_aa] = 1;
	} else {
	    $hydrophobic  [$prev_aa] = 0;
	}
	if ( $res_name =~ "TYR" ) {
	    $tyro  [$prev_aa]  = 1;
	} else {
	    $tyro  [$prev_aa]  = 0;
	}
	$centroid_x [$prev_aa] = $avg_x/$ctr;
	$centroid_y [$prev_aa] = $avg_y/$ctr;
	$centroid_z [$prev_aa] = $avg_z/$ctr;
    }

    close PDBFILE;

    $highest_aa = $res_number;
    $no_of_atoms[$prev_aa] = $ctr;

=pod
    for ( $aa1 = $lowest_aa; $aa1 < $highest_aa ; $aa1++ ) {
	printf " %4d:  %d  %d   %8.3f   %8.3f   %8.3f  \n",
	$aa1,  $hydrophobic[$aa1],   $tyro[$aa1], $centroid_x[$aa1] , $centroid_y[$aa1] ,  $centroid_z[$aa1];
    }
=cut

    $hydro_w_tyro = 0;
    $hydro = 0;
    $total = 0;
    for ( $aa1 = $lowest_aa; $aa1 <= $highest_aa ; $aa1++ ) {
	$total ++;
	if ( $tyro[$aa1] ) {
	    $hydro_w_tyro ++;
	}
	$no_neighbors[$aa1] = 0;
	if ( $hydrophobic[$aa1]) {
	    $hydro_w_tyro ++;
	    $hydro ++;
	    $b[$aa1] = $h[$aa1] = $no_neighbors[$aa1] = 0;
	    for ( $aa2 = $lowest_aa; $aa2 <= $highest_aa; $aa2++ ) {
		next if ( $aa1 == $aa2 ); 
		$x = $centroid_x[$aa1] - $centroid_x[$aa2];
		$y = $centroid_y[$aa1] - $centroid_y[$aa2];
		$z = $centroid_z[$aa1] - $centroid_z[$aa2];
		$r = sqrt ($x**2 + $y**2 + $z**2);
		if ( $r <= 10 ) {
		    $b[$aa1] ++;
		}
		if ($r <= 7.3 ){
		    $no_neighbors[$aa1]++;
		    if ($hydrophobic[$aa2]  ) {
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
	    if ( $hydrophobic [$aa1-1] || $tyro [$aa1-1]) {
		$h_fraction --;
	    }
	}
	if ( $aa1 < $highest_aa-1) {
	    $t--;
	    if ($hydrophobic [$aa1+1] || $tyro [$aa1+1]) {
		$h_fraction --;
	    }
	}
	$h_fraction /= $t;
	$h_exp = $h_fraction*$no_neighbors[$aa1];
	$totb += $b[$aa1];
	$toth  += ($h[$aa1]-$h_exp);
	
    }
    $score = $totb*$toth/($hydro**2);
}



sub process_bin () {
    $bin_number = $_[0];
    $bin[$bin_number][$noc] ++;
    $total[$bin_number] ++;

    if ( $score < $native_score ) {
	$perc [$bin_number][2] ++;
    }
    if ( $noc >= $noc_native ) {
	$perc [$bin_number][0] ++;
	if ( $score < $native_score ) {
	    $perc [$bin_number][1] ++;
	}
    }
}
