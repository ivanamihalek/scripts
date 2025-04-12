#! /usr/bin/perl -w


# for dna symmetry axis
(@ARGV == 9 ) ||
    die "Usage: carbon_line.pl  \@normal \@center_of_mass \@x_direction \n";

@normal = @ARGV[0..2];
@cm = @ARGV[3..5];
@x_dir =  @ARGV[6..8];
$cc_bond_length = 1.54;


$norm = 0;
for $i (0 ..2) {
    $j = ($i+1)%3;
    $k = ($i+2)%3;
    $y_dir[$k] = $normal[$i]*$x_dir[$j] -  $normal[$j]*$x_dir[$i];
    $norm += $y_dir[$k]*$y_dir[$k];
}
$norm = sqrt ($norm);
for $i (0 ..2) {
    $y_dir[$i] /= $norm;
}
	


$max = 10;


printf " %d \n\n", 2*$max+1;
$ctr = 0;
for ( $step_x = -$max;  $step_x <= $max; $step_x++ ) {
    for ( $step_y = -$max;  $step_y <= $max; $step_y++ ) {

	for $i (0 ..2) {
	    $r[$i] = $cm[$i] + $cc_bond_length*$step_x*$x_dir[$i]
		+ $cc_bond_length*$step_y*$y_dir[$i];
	}

	$ctr++;
	$crap = sprintf  "ATOM  %5d  C   UNK Z   1", 10000+$ctr;
	printf "%-30s%8.3f%8.3f%8.3f \n",
	   $crap, @r;
    }
}
