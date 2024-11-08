#! /usr/bin/perl -w 



defined ( $ARGV[0])  ||
    die "Usage: test_orth.pl    <tfm_file>.\n";

$tfmfile = $ARGV[0];

open ( TFM, "<$tfmfile") ||
    die "Cno $tfmfile: $!.\n";
# expects input in the format
# 
#$A[0][0]     $A[0][1]   $A[0][2]   $x0
#$A[1][0]     $A[1][1]   $A[1][2]   $y0
#$A[2][0]     $A[2][1]   $A[2][2]   $z0

$i = 0;
while ( <TFM> ) {
    @aux = split;
    for $j ( 0 .. 2) {
	$A[$i][$j] = $aux[$j];
    }
    $t[$i] = $aux[3];
    $i++;
}

close TFM;

for $i ( 0 .. 2) {
    for $j ( 0 .. 2) {
	$sum = 0;
	for $k ( 0 .. 2) {
	    $sum += $A[$i][$k]*$A[$j][$k];
	}
	printf " %8.3f  ", $sum;
    }
    print "\n";
}
