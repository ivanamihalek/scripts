#! /usr/bin/perl -w

$angle = 3.14/3;

$avg_x = 0;
$avg_y = 0;
$ctr = 0;
while ( <> ) {
    chomp;
    @aux = split;
    $crap[$ctr] = join (' ',@aux [0 .. 5]);
    $x[$ctr] = $aux[6];
    $y[$ctr] = $aux[7];
    $z[$ctr] = $aux[8];
    $avg_x += $x[$ctr];
    $avg_y += $y[$ctr];
    $ctr++;
   
}
$no_atoms = $ctr;

$avg_x /= $no_atoms;
$avg_y /= $no_atoms;

#printf " %7.3f  %7.3f \n", $avg_x, $avg_y;

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
    printf ("%-6s%5s  %-3s %3s %1s%4s     %7.3f %7.3f %7.3f \n",
	    split (' ', $crap[$ctr]), $x[$ctr], $y[$ctr], $z[$ctr]);
}
