#! /usr/bin/perl -w 
use Math::Trig; # trig functions and number pi

# read ina list <axis> <angle> and perform the tfmations consecutively

defined ( $ARGV[0])  && defined ( $ARGV[1] ) ||
    die "Usage: pdb_affine_tfm.pl   <pdb_name>  <tfm_file>.\n";

$pdbfile = $ARGV[0]     ;
$tfmfile = $ARGV[1];

open ( TFM, "<$tfmfile") ||
    die "Cno $tfmfile: $!.\n";

while ( <TFM> ) {
    ($axis, $angle) = split;
    push @axes, $axis;
    $angle = deg2rad ($angle);
    push @angles, $angle;
}

close TFM;

$no_tfms = $#axes + 1;
( $no_tfms  ) || die "no transformations requested in $tfmfile.\n";



open ( PDB, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

while ( <PDB> ) {
    if ( ! (/^ATOM/ || /^HETATM/) ) {
	print;
	next;
    }
    chomp;
    $crap = substr ($_, 0, 30);
    $crap2 = substr ($_, 54);
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;

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
    }

    printf  "%30s%8.3f%8.3f%8.3f%s \n",
	   $crap,  $xnew, $ynew, $znew, $crap2;
   
}

close PDB;

