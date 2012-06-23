#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# "ce" is a  structural alignment program by Shnyidalov et co
# it works better with the original pdb than with the one with extracted chains
# it doesnt ouput the pdb, ony affine tf
# the affine tfm transforms name 2 into name 1

(@ARGV >=2) || die "Usage: matrix_from_ce.pl <ce_output> <out name root>.\n";

$inf = $ARGV[0];
open (IF,"<$inf") || die "Cno $inf: $!.\n";

$name_root = $ARGV[1];

$line_ctr = -1;
$tfm_ctr  = -1;

# there might be multiple solutions - spit out the best one
while ( <IF> ) {
    if ( /\((.+?)\).+\((.+?)\).+\((.+?)\).+\((.+?)\)/ ) {
	$line_ctr++;
	if ( ! ($line_ctr%3) ) {
	    $line_ctr = 0;
	    $tfm_ctr++;
	}
	(defined $matrix[$tfm_ctr]) || ($matrix[$tfm_ctr] = "");
	$matrix[$tfm_ctr] .=   " $1  $2   $3  $4\n";
    }
}
$max_tfm_ctr = $tfm_ctr;
close IF;

#print $max_z;


foreach $tfm_ctr (0 .. $max_tfm_ctr) {

    $fn = "$name_root.$tfm_ctr.tfm";
    open (OF, ">$fn") || die "Cno $fn: $!.\n";
    print OF $matrix[$tfm_ctr];
    close OF;
}

