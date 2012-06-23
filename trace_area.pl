#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    next if ( /^%/ );
    next if ( ! /\S/ );
    last if ( /total/);
    chomp;
    @aux = split;
    push @cvg,  $aux[1];
    push @z, $aux[5]
}



$step_size = 0.05;
$no_steps = 1/$step_size;

$lower = 0;
$ctr = 0;
$total = 0;
for $step ( 1 .. $no_steps ) {
    $upper = $lower + $step_size ;
    $avg = 0;
    $n = 0;
    while ( $cvg[$ctr] <= $upper  &&   $ctr < $#z ) {
	$avg +=  $z[$ctr];
	$n++;
	$ctr++;
    }
    ( $n ) &&  ( $avg /= $n );
    #printf "%5.2f   %5.2f    %5.2f \n" , $lower,   $upper, $avg;
    $total += $avg;
    $lower = $upper;
}
$step = 0; #to get rid of interpreter warning

$total *= $step_size;
printf "\ntotal: %8.2f \n", $total;
