#! /usr/bin/perl -w

use Math::Trig;
$pi = 3.1415926536;
# for dna symmetry axis
(@ARGV == 7 ) ||
    die "Usage: carbon_sphere.pl \@origin radius \@sample_point\n";

@origin = @ARGV[0..2];
$R = $ARGV[3];
@sample_point = @ARGV[4..6];

$theta_0 = acos (($sample_point[2] - $origin[2])/$R);
$phi_0   = acos (($sample_point[0] - $origin[0])/($R*sin($theta_0)) );
($sample_point[1] - $origin[1] < 0 ) && ( $phi_0 = 2*$pi - $phi_0);
$theta_step = $pi/2000;
$phi_step = $pi/2000;

if (0)  {
    print "\n";
    printf  "%8.2lf %8.2lf  %8.2lf \n", @origin;
    printf  "%8.2lf %8.2lf  %8.2lf \n", @sample_point;
    printf  "%8.2lf %8.2lf  %8.2lf \n",  $theta_0, $phi_0, $phi_1;
    print "test\n";
    $x = $R*sin($theta_0)*cos($phi_0) + $origin[0];
    $y = $R*sin($theta_0)*sin($phi_0) + $origin[1] ;
    $z = $R*cos($theta_0) + $origin[2];
    printf  "%8.2lf %8.2lf  %8.2lf \n\n", $x, $y, $z;
    #exit;
}

$max = 6;
#printf " %d \n\n", 2*$max+1;
$ctr = 0;
for ( $step1 = -$max;  $step1 <= $max; $step1++ ) {
    $theta = $theta_0 + $step1*$theta_step;
    for ( $step2 = -$max;  $step2 <= $max; $step2++ ) {
	$phi = $phi_0 + $step2*$phi_step;
	$x = $R*sin($theta)*cos($phi) + $origin[0];
	$y = $R*sin($theta)*sin($phi) + $origin[1] ;
	$z = $R*cos($theta) + $origin[2];
	$ctr++;
	$crap = sprintf  "ATOM  %5d  C   UNK Z   1", 10000+$ctr;
	printf "%-30s%8.3f%8.3f%8.3f \n", $crap, $x, $y, $z;
    }
}
