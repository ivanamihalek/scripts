#! /usr/bin/perl -w
use IO::Handle;

$pdbnames = "almt_chains";

open (FH, "<$pdbnames" ) || 
    die "Cno $pdbnames: $! \n"; 



while ( <FH> ) { 
    next if  ( !/\S/ );
    chomp;
    $name = $_;
    $name =~ s/ //g;
    $noc =  find_noc ("$name/$name.pdb");
    print "$name  $noc \n";
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
    return  $no_of_contacts;

}
