#! /usr/gnu/bin/perl

$file1 = "ET_int.dat";

open ( FILE1, "<$file1") 
  || die "open fail $file1"; 

if (  defined $ARGV[0] ) {
    $rank0 = $ARGV[0];
} else {
    $rank0 = 1;
}
$cumul =0;
$total =0;
while ( <FILE1> ) {
    next if /%/;
    ($rank, $population) = split;
    if ( $rank <= $rank0) {
	$cumul += $population;
	
    }
    $total += $population;
}
print "rank $rank0 or higher: $cumul ( $total )\n";
