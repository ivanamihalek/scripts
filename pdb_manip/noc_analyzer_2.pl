#! /usr/bin/perl -w
use IO::Handle;

$pdbnames = "tmp.list";
$path = "/sycamore/folding_data/dd/multiple/";
$results_path = "/sycamore/folding_data/trace/decoy/";

@sets = ("4state_reduced/", "fisa/",  "fisa_casp3/",  "hg_structal/",  
	 "lattice_ssfit/", "lmds/", "lmds_v2/");

open (FH, "<$pdbnames" ) || 
    die "Cno $pdbnames: $! \n"; 


#open (OF, ">noc_all_3") ||
#    die "Cno noc_all_3: $! \n"; 
OF = STDOUT;

$home = `pwd`;

while ( <FH> ) { 
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
	    print "$name belongs to  $set.\n";
	    chdir $full;
	    open (RMS, "<rmsds") ||
		die "Cno $full/rmsds: $! \n"; 
	    for $j (1..6) {
		for  $i (0..1500) {
		    $bin[$j][$i] = 0;
		}
		$total[$j] = 0;
		$perc[$j][0]  = $perc[$j][1]  = $perc[$j][2]  = $perc[$j][3]  = 0;
	    }
	    while ( <RMS> ) {
		chomp;
		@aux = split;
		$full2 = $full."/".$aux[4];
		$current_name = $aux[4];
		if ( $current_name =~ "$name.pdb" ) {
		    find_noc ( $full2 );
		    printf OF "$current_name: noc in native: $noc\n"; 
		    OF -> autoflush(1);
		    $noc_native = $noc;
		    $sum_name = $results_path."$name_native/$name_native.azs.psi.cluster_report.summary";
		    @aux =
			split ' ', `tail -2  $sum_name | head -1`;
		    ($zs_native, $za_native, $zsa_native) = @aux[2..4];
		}
	    }
	    seek RMS, 0, 0; # this is rewinding

	    while ( <RMS> ) {
		chomp;
		undef @aux;
		@aux = split;
		$full2 = $full."/".$aux[4];
		$current_name = $aux[4];
		$dist = $aux[$#aux];
		find_noc ( $full2 );
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
			for $j (1 ..3) {
			    $perc [$i][$j] /= $perc [$i][0];
			}
		    } else {
			for $j (1 ..3) {
			    $perc [$i][$j] = -1;
			}
		    }
		    $perc [$i][0] /= $total[$i];
		} else {
		    $perc[$i][0]  = $perc[$i][1]  = $perc[$i][2]  = $perc[$i][3]  = -1;
		}
		printf OF " %2d  %5d   %8.3lf     %8.3lf  %8.3lf  %8.3lf   ", 
		$i,  $total[$i],  $perc [$i][0], $perc [$i][1], $perc [$i][2], $perc [$i][3] ;
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





sub find_noc {
    $r_cutoff = 5;
    $noc = 0;
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
	    if (! defined $lowest_aa ) {
		$lowest_aa = $res_number;
	    }
	    if ($res_number != $prev_aa ) {
		$no_of_atoms[$prev_aa] = $ctr;
		$ctr = 0;
		$prev_aa =  $res_number;
	    }
	    $atom_number = join ('', @aux[6..10]) ;
	    $x =   join ('',@aux[30..37]);
	    $y =  join ('', @aux[38..45]);
	    $z =  join ('', @aux[46..53]);
	    $atom [$res_number][$ctr][0] = $atom_number;
	    $atom [$res_number][$ctr][1] = $x;
	    $atom [$res_number][$ctr][2] = $y;
	    $atom [$res_number][$ctr][3] = $z;
	    $ctr++;
	}
    }

    $highest_aa = $res_number;
    $no_of_atoms[$prev_aa] = $ctr;

    $no_of_contacts = 0;
    for ( $aa1 = $lowest_aa; $aa1 < $highest_aa ; $aa1++ ) {

	if ( defined $no_of_atoms[$aa1]  && $no_of_atoms[$aa1] > 0 ) {

	  AA2:	for ( $aa2 = $aa1+1; $aa2 <= $highest_aa; $aa2++ ) {

	      if ( defined $no_of_atoms[$aa2]  && $no_of_atoms[$aa2] > 0 ) {

		  $r_min = 1000.0;
		  for ($ctr1=0; $ctr1<$no_of_atoms[$aa1]; $ctr1++) {
		      $x1 = $atom[$aa1][$ctr1][1];
		      $y1 = $atom[$aa1][$ctr1][2];
		      $z1 = $atom[$aa1][$ctr1][3];

		      for ($ctr2=0; $ctr2 <$no_of_atoms[$aa2]; $ctr2++) {
			  $x2 = $atom[$aa2][$ctr2][1];
			  $y2 = $atom[$aa2][$ctr2][2];
			  $z2 = $atom[$aa2][$ctr2][3];
			
			  $r = ($x1-$x2)*($x1-$x2)+ ($y1-$y2)*($y1-$y2)
			      +($z1-$z2)*($z1-$z2);
			  $r = sqrt ($r);
			  if ($r <  $r_min ) {
			      $r_min = $r; 
			      if ($r_min < $r_cutoff) {
				  $no_of_contacts ++;
				  next AA2;
			      }
			  }
		      }
		  }
	        
		
	      }
	  }
	
	}
    }
    close PDBFILE;
    $noc = $no_of_contacts;

}

sub process_bin () {
    $bin_number = $_[0];
    $bin[$bin_number][$noc] ++;
    $total[$bin_number] ++;
    if ( $noc > $noc_native ) {
	$perc [$bin_number][0] ++;
	# get rid of the .pdb extension
	$aux_name = substr $current_name, 0, (length $current_name) - 4;
	$sum_name = $results_path."$name_native/$aux_name.azs.psi.cluster_report.summary";
	@aux =
	    split ' ', `tail -2  $sum_name | head -1`;
	($zs, $za, $zsa) = @aux[2..4];
	if ( $zs < $zs_native ) {
	    $perc [$bin_number][1] ++;
	}
	if ( $za < $za_native ) {
	    $perc [$bin_number][2] ++;
	}
	if ( $zsa < $zsa_native ) {
	    $perc [$bin_number][3] ++;
	}
    }
}
