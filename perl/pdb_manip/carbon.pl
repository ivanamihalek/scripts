#! /usr/bin/perl -w


# for dna symmetry axis
(@ARGV >= 1 ) ||
    die "Usage: carbon.pl <coords file> \n";

($coords) =  @ARGV;

open ( COORDS, "<$coords") ||
    die "Cno $coords: $!.\n";

$ctr = 0;

while ( <COORDS> ) {
    chomp;
    ( $x, $y, $z) = split;
    $ctr++;
    $crap = sprintf  "ATOM  %5d  C   UNK Z   1", 10000+$ctr;
    printf "%-30s%8.3f%8.3f%8.3f \n", $crap,  $x, $y, $z;

    
}

close COORDS;

