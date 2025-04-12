#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# "ce" is a  structural alignment program by Shnyidalov et co
# it works better with the original pdb than with the one with extracted chains
# it doesnt ouput the pdb, ony affine tf
# the affine tfm transforms name 2 into name 1

(@ARGV) || die "Usage: matrix_from_ce.pl <ce_output>.\n";

$inf = $ARGV[0];
open (IF,"<$inf") || die "Cno $inf: $!.\n";

$max_z = -100;
$max_ctr = -1;
$ctr = 0; # there might be multiple solutions - spit out the best one
while ( <IF> ) {
    if ( /^Alignment/ ) {
	/Z\-Score = ([\d\.]+) /;
	$zscore[$ctr] = $1;
	if ($max_z <  $zscore[$ctr] ) {
	    $max_z = $zscore[$ctr];
	    $max_ctr = $ctr;
	}
    } elsif ( /\((.+?)\).+\((.+?)\).+\((.+?)\).+\((.+?)\)/ ) {
	$matrix[$ctr] .=   " $1  $2   $3  $4\n";
	( /Z2/ ) && $ctr++; 
    }
}

close IF;

#print $max_z;
print $matrix[$max_ctr];

