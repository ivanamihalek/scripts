#! /usr/bin/perl -w


# for dna symmetry axis
(@ARGV >= 2 ) ||
    die "Usage: carbon_surface.pl <hyper or caten>  <params file> \n";

($surftype, $params) =  @ARGV;

( $surftype eq "hyper" || $surftype eq "caten") ||
    die "surface type $surftype not recognized \n";



open ( PARAMS, "<$params") ||
    die "Cno $params: $!.\n";

$i = 0;
while ( <PARAMS> ) {
    if ($i < 3 ) {
	@aux = split;
	for $j ( 0 .. 2) {
	    $A[$i][$j] = $aux[$j];
	}
	$t[$i] = $aux[3];
    } else {
	@params = split;
    }
    $i++;
}


$cc_bond_length = 1.7;

if ( $surftype eq "hyper") {
    ($a, $b, $c) =  @params;
    $max = 10;
    $ctr = 0;
    for ( $step1 = -$max;  $step1 <= $max; $step1++ ) {
	$x = $step1*0.1;
	for ( $step2 = -$max;  $step2 <= $max; $step2++ ) {
	    $y = $step2*0.1;
	    next if ( $x*$x/($a*$a) + $y*$y/($b*$b) < 1 );
	    $z = $c*  sqrt ( $x*$x/($a*$a) + $y*$y/($b*$b) -1 );
	    $xnew = $A[0][0]*$x +   $A[0][1]*$y  +  $A[0][2]*$z;
	    $ynew = $A[1][0]*$x +   $A[1][1]*$y  +  $A[1][2]*$z;
	    $znew = $A[2][0]*$x +   $A[2][1]*$y  +  $A[2][2]*$z;
	    $xnew += $t[0];
	    $ynew += $t[1];
	    $znew += $t[2];
	    $ctr++;
	    $crap = sprintf  "ATOM  %5d  C   UNK Z   1", 10000+$ctr;
	    if ( 0) {
		printf "%-30s%8.3f%8.3f%8.3f \n",
		$crap,  $x, $y, $z;
	    } else {
		printf "%-30s%8.3f%8.3f%8.3f \n",
		$crap,  $xnew, $ynew, $znew;
	    }
	}
    }

} elsif (  $surftype eq "caten") {
    $r = shift @params;
    $max = 20;
    $ctr = 0;
    for ( $step1 = -$max;  $step1 <= $max; $step1++ ) {
	$u = $step1/10;
	$cosh = ( exp($u) +  exp(-$u))/2;
	for ( $step2=0; $step2<=2*$max; $step2++ ) {
	    $v = 3.14/$max*$step2;
	    $x = $r * $cosh * cos($v);
	    $y = $r * $cosh * sin($v);
	    $z = $r*$u;
	    $xnew = $A[0][0]*$x +   $A[0][1]*$y  +  $A[0][2]*$z;
	    $ynew = $A[1][0]*$x +   $A[1][1]*$y  +  $A[1][2]*$z;
	    $znew = $A[2][0]*$x +   $A[2][1]*$y  +  $A[2][2]*$z;
	    $xnew += $t[0];
	    $ynew += $t[1];
	    $znew += $t[2];
	    $ctr++;
	    $crap = sprintf  "ATOM  %5d  C   UNK Z   1", 10000+$ctr;
	    if ( 0) {
		printf "%-30s%8.3f%8.3f%8.3f \n",
		$crap,  $x, $y, $z;
	    } else {
		printf "%-30s%8.3f%8.3f%8.3f \n",
		$crap,  $xnew, $ynew, $znew;
	    }
	}
    }
}

