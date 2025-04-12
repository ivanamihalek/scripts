#! /usr/bin/perl -w 

#$angle = 3.14/3;
$angle = 0.0;


$x0 =    100.502;
$y0 =    100.731;
$z0 =    100.944;


$avg_x = 0;
$avg_y = 0;
$avg_z = 0;
$ctr   = 0;


while ( <> ) {
    next if ( ! /\S/);
    chomp;
    $crap[$ctr] = substr ($_, 0, 30);
    @aux = split  ( ' ', substr ($_, 30));
    $x[$ctr] = $aux[0];
    $y[$ctr] = $aux[1];
    $z[$ctr] = $aux[2];
    $avg_x += $x[$ctr];
    $avg_y += $y[$ctr];
    $avg_z += $z[$ctr];
    $ctr++;
   
}
$no_atoms = $ctr;

$avg_x /= $no_atoms;
$avg_y /= $no_atoms;
$avg_z /= $no_atoms;

#printf " %7.3f  %7.3f   %7.3f \n", $avg_x, $avg_y, $avg_z;
#exit;


for $ctr (0 .. $no_atoms-1) {

    # translate
    $x[$ctr] -= $avg_x;
    $y[$ctr] -= $avg_y;
    # rotate
    $xnew = $x[$ctr]*cos($angle) - $y[$ctr]*sin($angle);
    $ynew = $x[$ctr]*sin($angle) + $y[$ctr]*cos($angle);


    # translate back
    $x[$ctr] = $xnew + $avg_x;
    $y[$ctr] = $ynew + $avg_y;

    # now translate by the required amount;
    $x[$ctr] += $x0;
    $y[$ctr] += $y0;
    $z[$ctr] += $z0;

    printf ("%30s%8.3f%8.3f%8.3f \n",
	   $crap[$ctr],  $x[$ctr], $y[$ctr], $z[$ctr]);

}


