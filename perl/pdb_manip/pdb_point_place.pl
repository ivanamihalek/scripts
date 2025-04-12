#! /usr/bin/perl -w 
use Math::Trig; # trig functions and number pi

# read in a pdbfile and a point which should be moved to +z axis direction

defined ( $ARGV[3] ) ||
    die "Usage: pdb_point_place.pl   <pdb_name>  <x>  <y>  <z>  [<res name>].\n";

$pdbfile = $ARGV[0];
$x0 = $ARGV[1];
$y0 = $ARGV[2];
$z0 = $ARGV[3];

$res_name = "";
( defined  $ARGV[4] ) && ($res_name = uc $ARGV[4]);



$x_ctr = 0;
$y_ctr = 0;
$z_ctr = 0;
$ctr   = 0;

open ( PDB, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";
undef $/;
$_ = <PDB>;
$/ = "\n";
close PDB;

@pdblines = split '\n', $_; 

foreach  ( @pdblines ) { 
    next if ( ! /\S/);
    next if ( ! (/^ATOM/ || /^HETATM/) );
    chomp;
    $crap = substr ($_, 0, 30);
    $crap2 = substr ($_, 54);
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;
    $x_ctr += $x;
    $y_ctr += $y;
    $z_ctr += $z;
    $ctr++;
   
}
$no_atoms = $ctr;


$x_ctr /= $no_atoms;
$y_ctr /= $no_atoms;
$z_ctr /= $no_atoms;

#printf "center %8.3f  %8.3f  %8.3f \n", $x_ctr, $y_ctr, $z_ctr;
#exit;

# orient the pdb file so that the $center_residue faces the viewer
$x0  -=  $x_ctr;   $y0  -=  $y_ctr;   $z0  -=  $z_ctr;


@axes   = ();
@angles = ();


if ( !$x0 && !$y0 ) {
    #do nothing
} elsif ( $x0 && !$y0) { 
    # rotate about  y
    if ( $z0 ) { 
	$theta = atan2 ($x0, $z0); 
    } else {
	$theta =  pi/2; 
    } 
    push @axes, "y"; 
    push @angles, -$theta; 

} elsif ( $y0 && !$x0 ) { 
    # rotate about  x 
    if ( $z0 ) { 
	$theta = atan2 ($y0, $z0);
    } else { 
	$theta =  pi/2; 
    } 
    push @axes, "x"; 
    push @angles, $theta;

} else {  
    $phi =   atan2 ($y0, $x0); 
    push @axes, "z"; 
    push @angles, -$phi;
   
    if ( $z0 ) { 
	$rho     = sqrt ( $x0*$x0 + $y0*$y0); 
	$theta   = atan2 ($rho,$z0);
    } else { 
	$theta =  pi/2; 
    } 
    push @axes, "y"; 
    push @angles, -$theta;
} 

# the thing should point in the -z direction -needed for rasmol, but not for pymol
#push @axes, "y"; 
#push @angles, -(pi);


$min_het_x = $min_het_y = $min_het_z = 100000;
$max_het_x = $max_het_y = $max_het_z = -100000;
$het_ctr_x = 0;
$het_ctr_y = 0;
$het_ctr_z = 0;
$no_atoms  = 0;

if ($res_name) {
    foreach  ( @pdblines ) { 

	next if ( ! /^HETATM/);
	$input_res_name = substr $_, 17, 3;
	$input_res_name =~ s/\s//g;
	next if ( $res_name ne   $input_res_name);
	$x = substr $_, 30, 8; $x =~ s/\s//g;
	$y = substr $_, 38, 8; $y =~ s/\s//g;
	$z = substr $_, 46, 8; $z =~ s/\s//g;

	$x -= $x_ctr;   $y -= $y_ctr;   $z -= $z_ctr;
	$znew = $z;
	$xnew = $x;
	$ynew = $y;



	for $ctr ( 0 .. $#axes ) {
	    $axis  = $axes  [$ctr];
	    $angle = $angles[$ctr];
	    if ( $axis eq "z" ) {
		$znew = $z;
		$xnew = $x*cos($angle) - $y*sin($angle);
		$ynew = $y*cos($angle) + $x*sin($angle);
		
	    } elsif  ( $axis eq "x" ) {
		$xnew = $x;
		$ynew = $y*cos($angle) - $z*sin($angle);
		$znew = $z*cos($angle) + $y*sin($angle);
		
	    } elsif  ( $axis eq "y" ) {
		$ynew = $y;
		$znew = $z*cos($angle) - $x*sin($angle);
		$xnew = $x*cos($angle) + $z*sin($angle);

	    } else {
		die "Unrecognized axis: $axis.\n";
	    }
	    $z = $znew;
	    $x = $xnew;
	    $y = $ynew;
	
	}
	$het_ctr_x += $x;
	$het_ctr_y += $y;
  	$het_ctr_z += $z;
	$no_atoms ++;
  
	(  $x < $min_het_x) && ($min_het_x = $x);
	(  $y < $min_het_y) && ($min_het_y = $y);
	(  $z < $min_het_z) && ($min_het_z = $z);
    
    
	(  $x > $max_het_x) && ($max_het_x = $x);
	(  $y > $max_het_y) && ($max_het_y = $y);
	(  $z > $max_het_z) && ($max_het_z = $z);
    
    }
    $min_het_x -= 3;
    $min_het_y -= 3;
    $max_het_x += 3;
    $max_het_y += 3;
    $het_ctr_x /= $no_atoms;
    $het_ctr_y /= $no_atoms;
    $het_ctr_z /= $no_atoms;
}


foreach  ( @pdblines ) { 
    if ( ! (/^ATOM/ || /^HETATM/) ) {
	print;
	next;
    }
    chomp;
    $crap = substr ($_, 0, 30);
    $crap2 = substr ($_, 54);
    $x = substr $_,30, 8; $x =~ s/\s//g;
    $y = substr $_,38, 8; $y =~ s/\s//g;
    $z = substr $_, 46,8; $z =~ s/\s//g;

    $x -= $x_ctr;   $y -= $y_ctr;   $z -= $z_ctr;
    $znew = $z;
    $xnew = $x;
    $ynew = $y;



    for $ctr ( 0 .. $#axes ) {
	$axis  = $axes  [$ctr];
	$angle = $angles[$ctr];
	if ( $axis eq "z" ) {
	    $znew = $z;
	    $xnew = $x*cos($angle) - $y*sin($angle);
	    $ynew = $y*cos($angle) + $x*sin($angle);
		
	} elsif  ( $axis eq "x" ) {
	    $xnew = $x;
	    $ynew = $y*cos($angle) - $z*sin($angle);
	    $znew = $z*cos($angle) + $y*sin($angle);
	    
	} elsif  ( $axis eq "y" ) {
	    $ynew = $y;
	    $znew = $z*cos($angle) - $x*sin($angle);
	    $xnew = $x*cos($angle) + $z*sin($angle);

	} else {
	    die "Unrecognized axis: $axis.\n";
	}
	$z = $znew;
	$x = $xnew;
	$y = $ynew;
	
   }
    $print = 1;
    if ( $res_name ) {
	 if  ( /^ATOM/  && $z > $min_het_z && 
	       $x > $min_het_x && $x < $max_het_x &&
	       $y > $min_het_y && $y < $max_het_y )  {
	     $print = 0;
	 } else {
	     $dist = 0.0;
	     foreach ( $x- $het_ctr_x, $y- $het_ctr_y, $z- $het_ctr_z) {
		 $dist += $_*$_;
	     }
	     $dist = sqrt ($dist);
	     ($dist > 30 )  && ($print = 0);
	 }
	
    } 

    $print  && printf  "%30s%8.3f%8.3f%8.3f%s \n",
	$crap,  $xnew, $ynew, $znew, $crap2;
    
}

#print "HETATM 3077  FE  IRO B1007       0.000   0.000   0.000\n";
