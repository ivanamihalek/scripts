#! /usr/bin/perl -w
use IO::Handle;
sub find_noc(@);

(defined  $ARGV[0]) || die "Usage: noc.pl <pdbfile>.\n";
$pdbfile = $ARGV[0];
find_noc($pdbfile);

##################################




sub find_noc(@) {
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
	    $res_number  = substr $_, 22, 4;  $res_number=~ s/\s//g;
	    if (! defined $lowest_aa ) {
		$lowest_aa = $res_number;
	    }
	    if ($res_number != $prev_aa ) {
		$no_of_atoms[$prev_aa] = $ctr;
		$ctr = 0;
		$prev_aa =  $res_number;
	    }

	    $atom_number  = substr $_, 6, 5;  $atom_number  =~ s/\s//g;

	    $x = substr $_,30, 8;  $x=~ s/\s//g;
	    $y = substr $_,38, 8;  $y=~ s/\s//g;
	    $z = substr $_, 46, 8; $z=~ s/\s//g;

	    $atom [$res_number][$ctr][0] = $atom_number;
	    $atom [$res_number][$ctr][1] = $x;
	    $atom [$res_number][$ctr][2] = $y;
	    $atom [$res_number][$ctr][3] = $z;
	    $ctr++;
	}
    }
    close PDBFILE;

    $highest_aa = $res_number;
    $no_of_atoms[$prev_aa] = $ctr;

    for ( $aa1 = $lowest_aa; $aa1 < $highest_aa ; $aa1++ ) {

	if ( defined $no_of_atoms[$aa1]  && $no_of_atoms[$aa1] > 0 ) {

	    for ( $aa2 = $aa1+1; $aa2 <= $highest_aa; $aa2++ ) {

	      if ( defined $no_of_atoms[$aa2]  && $no_of_atoms[$aa2] > 0 ) {

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

			  if ($r_min < $r_cutoff) {
			      $no_of_contacts ++;
			  }
		      }
		  }
	        
		
	      }
	      print "$aa1  $aa2 $no_of_contacts \n";

	  }
	  
	
	}
    }

}
