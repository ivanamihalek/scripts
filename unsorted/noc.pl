#! /usr/bin/perl -w
use IO::Handle;

$pdbnames = "tmp7";
$path = "/sycamore/folding_data/dd/multiple/";
$results = "/home/protean5/imihalek/projects/cow/decoys/dd/multiple/";

@sets = ("lmds/","4state_reduced/", "fisa/",  "fisa_casp3/",  "hg_structal/",  
	 "lattice_ssfit/",  "lmds_v2/");

open (FH, "<$pdbnames" ) || 
    die "Cno $pdbnames: $! \n"; 



$home = `pwd`;

while ( <FH> ) { 
    next if  ( ! (/\w/));
    chomp;
    $native_name = $_;
    @aux = split ('', $_);
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
	    $ok = 1;
	    chdir $full;
	    open (RMS, "<rmsds") ||
		die "Cno $full/rmsds: $! \n"; 
	    $dirname = $results.$native_name;
	    open (OF, ">$dirname/noc") ||
		die "Cno $dirname/noc: $! \n"; 
	    while ( <RMS> ) {
		chomp;
		@aux = split;
		$full2 = $full."/".$aux[4];
		$current_name = $aux[4];
		if ( $current_name =~ "$name.pdb" ) {
		    find_noc ( $full2 );
		    printf OF "$current_name   $noc\n"; 
		    OF -> autoflush(1);
		    $k = $noc;
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
		print OF "$current_name  $noc \n";
	    }
	    close OF;
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
