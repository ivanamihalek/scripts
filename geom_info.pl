#! /usr/gnu/bin/perl -w
use IO::Handle; # for flushing


(defined $ARGV[0]   ) ||
    die "usage: geom_info.pl  <pdb_list>  \n.";

$data_path = "."; 
$pdblist = $ARGV[0]; 
$resfile  = $pdblist. ".geom";
$failfile  = $pdblist. ".fail";
$pdblist = "$data_path/".$ARGV[0]; 
print "output: $resfile \n";

open (FAILFILE,">$failfile\n") ||
    die "cno $failfile: $! \n";


open (RESFILE,">$resfile\n") ||
    die "cno $resfile file: $! \n";

open (PDBLIST, "<$pdblist") ||
    die "could not open $pdblist.\n";
while (<PDBLIST>) {

    $begin = time;
    chomp;
    $name = $_;
    $sumfile = "$data_path/"."$name/"."$name.psi.2.cluster_report.summary";
    $pdbfile = "$data_path/"."$name/"."$name.pdb";
    if ( open (SUMFILE, "<$sumfile") ) { 

	    print "$name ...";
	    SUM: while ( <SUMFILE>) {
	    if (defined $_ &&  /max/) {
		chomp;
		@aux = split;
		    
		if ( $aux[2] > -50) {
		    $length = 0;
		    $no_of_contacts     = 0;
		    #$maxvals = join ("   ", @aux[2..4]);
		    $maxvals = $aux[2];
		    #process_pdb();
		    print RESFILE  "$name    $length   $no_of_contacts   $maxvals \n";	
		    RESFILE -> autoflush(1);

		} else {
		    print FAILFILE "cvg to big ... ";
		    FAILFILE -> autoflush(1);
		}
		last SUM; 
	    }
	}
	close SUMFILE;

    } else {
	print FAILFILE "$name: cno $sumfile: $!\n";
	FAILFILE -> autoflush(1);
	next;
    }
    print " done (", time-$begin,"s)\n";
    
}

close PDBLIST;

close FAILFILE;

close RESFILE;

sub process_pdb() {

    open (PDBFILE, "<$pdbfile") ||
	die "could not open $pdbfile.\n";

    $r_cutoff = 5;
    $prev_aa  = 0; $ctr = 0;
    $lowest_aa  = -1;
    while ( <PDBFILE> ) {
	chomp;
	@aux = split '';
	$res_number = join ('', @aux[22..25]);
	if ( $lowest_aa < 0) {
	    $lowest_aa = $res_number;
	}
	if ($res_number != $prev_aa ) {
	    $no_of_atoms[$prev_aa] = $ctr;
	    $ctr = 0;
	    $prev_aa =  $res_number;
	}
	$atom_number = join ('', @aux[6..10]) ;
	$x =   join ('',@aux[30..37]); # these number come from PDB spec
	$y =  join ('', @aux[38..45]);
	$z =  join ('', @aux[46..53]);
	$atom [$res_number][$ctr][0] = $atom_number;
	$atom [$res_number][$ctr][1] = $x;
	$atom [$res_number][$ctr][2] = $y;
	$atom [$res_number][$ctr][3] = $z;
	$ctr++;
    }

    $highest_aa = $res_number;
    $no_of_atoms[$prev_aa] = $ctr;
    $length = $highest_aa - $lowest_aa +1;

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

}
