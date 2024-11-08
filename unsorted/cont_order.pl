#! /usr/gnu/bin/perl -w


(defined $ARGV[0]   ) ||
    die "usage: cont_mat.pl  <pdb_list>  \n.";

$pdblist = $ARGV[0];

#$pdbfile = $ARGV[0].".pdb";

$r_cutoff = 4;



open (PDBLIST, "<$pdblist") ||
    die "could not open $pdblist.\n";
$min = 10000;
$max = -1;
$avg = 0;
$no_files = 0;
while (<PDBLIST>) {

    $no_files++;
    chomp;
    #$pdbfile = "$_/"."$_.pdb";
    $pdbfile = $_;



    open (PDBFILE, "<$pdbfile") ||
	die "could not open $pdbfile.\n";

   # print "$pdbfile:  ";
    $ctr = 0;
    $old_res_seq = -1;
    $res_ctr = 0;
    while ( <PDBFILE> ) {
	chomp;
	# looks like I have to format it seriously
	$record = substr $_, 0, 6;  $record =~ s/\s//g;
	next if ( ! ($record eq "ATOM" ));
	$serial = substr $_, 6, 5;  $serial =~ s/\s//g;
	$name = substr $_,  12, 4 ;  $name =~ s/\s//g; 
	next if ( substr ($name, 0,1) eq "H" );
	#$name =~ s/R//;$name =~ s/P//;$name =~ s/A//;
	$name =~ s/\*//g; 
    
	$alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
	$res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
	$chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	if ( $res_seq != $old_res_seq ) {
	    $res_ctr++;
	    $resnum[$res_seq] = $res_ctr;
	    if ( $old_res_seq > 0  )  {
		$no_of_atoms[$old_res_seq] = $ctr;
	    }
	    $ctr = 0;
	    $old_res_seq = $res_seq;
	}
	$i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
	$x = substr $_,30, 8;  $x=~ s/\s//g;
	$y = substr $_,38, 8;  $y=~ s/\s//g;
	$z = substr $_, 46, 8; $z=~ s/\s//g;
	if ( ! defined $lowest_aa ) {
	    $lowest_aa = $res_seq;
	}
	$atom [$res_seq][$ctr][0] = $atom_number;
	$atom [$res_seq][$ctr][1] = $x;
	$atom [$res_seq][$ctr][2] = $y;
	$atom [$res_seq][$ctr][3] = $z;
	$ctr++;
    }
   # exit;
    close PDBFILE;
    $highest_aa = $res_seq;
    $no_of_atoms[$old_res_seq] = $ctr;

    $no_of_contacts = 0;

    for ( $aa1 = $lowest_aa; $aa1 < $highest_aa ; $aa1++ ) {

	if ( defined $no_of_atoms[$aa1]  && $no_of_atoms[$aa1] > 0 ) {

	  AA2:	for ( $aa2 = $aa1+1; $aa2 <= $highest_aa; $aa2++ ) {

	      if ( defined $no_of_atoms[$aa2]  && $no_of_atoms[$aa2] > 0 ) {

		$r_min = 1000.0;

		$no_of_contacts = 0;
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
			    if ($r_min <= $r_cutoff) {
				$no_of_contacts ++;
				#next AA2;
			    }
			}
		    }
		}
		#printf " %5d  %5d  %8.4f  \n", $resnum[$aa1], $resnum[$aa2 ], $r_min;
	        if ( $no_of_contacts ) {
		    print "$resnum[$aa1]\t $resnum[$aa2 ]\t$no_of_contacts\n";
		    #printf "$resnum[$aa1]\t $resnum[$aa2 ]\t1.0\n";
		} else {
		    #printf "$resnum[$aa1]\t $resnum[$aa2 ]\t0.0\n";
		}
	    }
	} 
	
    } 
} 

    exit;

print "\tnumber of contacts =  $no_of_contacts\n";
    $avg += $no_of_contacts;
    if ($no_of_contacts < $min ) {
	$min = $no_of_contacts;
	$min_name = $pdbfile;
    } 
    if ($no_of_contacts > $max) {
	$max = $no_of_contacts;
	$max_name = $pdbfile;
    }
}
$avg /= $no_files;
printf "\n\t min: $min ($min_name) \n\t max: $max ($max_name)\n";
printf "\t avg: $avg\n\n"; 
close PDBLIST;
