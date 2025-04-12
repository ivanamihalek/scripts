#! /usr/bin/perl -w 
use Math::Trig; # trig functions and number pi
use POSIX qw(ceil floor);

# read in a pdbfile and a point which should be moved to +z axis direction

defined ( $ARGV[3] ) ||
    die "Usage: pdb_point_place.pl   <pdb_name>  <x>  <y>  <z>.\n";

$pdbfile = $ARGV[0];
$x0 = $ARGV[1];
$y0 = $ARGV[2];
$z0 = $ARGV[3];




$x_ctr = 0;
$y_ctr = 0;
$z_ctr = 0;
$ctr   = 0;

open ( PDB, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

while ( <PDB> ) {
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

close PDB;

$x_ctr /= $no_atoms;
$y_ctr /= $no_atoms;
$z_ctr /= $no_atoms;


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

# the thing should point in the -z direction
push @axes, "y"; 
push @angles, -(pi);


open ( PDB, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";



while ( <PDB> ) {
    if ( ! (/^ATOM/ || /^HETATM/ ) ) {
	#print;
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
    (defined $zmax) || ( $zmax = $znew);
    ( $zmax < $znew ) && ( $zmax = $znew );

    (defined $zmin) || ( $zmin = $znew);
    ( $zmin > $znew ) && ( $zmin = $znew );

    
}

close PDB;

$z = $z0;
$x = $x0;
$y = $y0;
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

$slabbing = ( $zmax - $znew  )/ ( $zmax - $zmin )*100;
printf " %d \n", ceil ($slabbing) ;

sub round {
    my($number) = shift;
    return int($number + .5);
}

