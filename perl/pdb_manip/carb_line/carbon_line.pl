#! /usr/bin/perl -w


# for dna symmetry axis
(@ARGV == 6 ) ||
    die "Usage: carbon_line.pl  \@p \@center_of_mass\n";

@p = @ARGV[0..2];
@cm = @ARGV[3..5];

$cc_bond_length = 1.54;

$max = 10;

printf " %d \n\n", 2*$max+1;
$ctr = 0;
for ( $step = -$max;  $step <= $max; $step++ ) {
    $x = $cm[0]+$step*$cc_bond_length*$p[0];
    $y = $cm[1]+$step*$cc_bond_length*$p[1];
    $z = $cm[2]+$step*$cc_bond_length*$p[2];
    $ctr++;
    $crap = sprintf  "ATOM  %5d  C   UNK Z   1", 10000+$ctr;
    printf "%-30s%8.3f%8.3f%8.3f \n",
	   $crap,  $x, $y, $z;
}
