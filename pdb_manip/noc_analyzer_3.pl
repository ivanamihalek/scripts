#! /usr/bin/perl -w 
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


open (OF, ">noc_all_4") ||
    die "Cno noc_all_4: $! \n"; 

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
		$current_name = $aux[0];
		$noc = $aux[2];
		if ( $current_name =~ "$name.pdb" ) {
		    printf OF  "$current_name: noc in native: $noc\n"; 
		    printf  "$current_name: noc in native: $noc\n"; 
		    OF -> autoflush(1);
		    $noc_native = $noc;
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
		next if ( "$name.pdb" =~ $current_name );
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
	    close NOC;
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
		    $tmp = $perc [$i][0];
		    $perc [$i][0] /= $total[$i];
		} else {
		    $perc[$i][0]  = $perc[$i][1]  = $perc[$i][2]  = $perc[$i][3]  = -1;
		    $tmp = $perc [$i][0];
		}
		printf OF " %2d  %5d  %5d    %8.3lf     %8.3lf  %8.3lf  %8.3lf   ", 
		$i,  $total[$i],  $tmp,  $perc [$i][0], $perc [$i][1], $perc [$i][2], $perc [$i][3] ;
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





sub process_bin () {
    $bin_number = $_[0];
    $bin[$bin_number][$noc] ++;
    $total[$bin_number] ++;
    if ( $noc >= $noc_native ) {
	$perc [$bin_number][0] ++;
	# get rid of the .pdb extension
	$aux_name = substr $current_name, 0, (length $current_name) - 4;
	$sum_name = $results_path."$name_native/$aux_name.zs.psi.cluster_report.summary";
	( -e $sum_name ) ||
	    die "could not find $sum_name (curent: $current_name).\n";
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
