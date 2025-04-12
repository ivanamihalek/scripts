#!/usr/bin/perl -w

(@ARGV  ) ||
    die "Usage: $0 <dssp file> [<chain>] \n";


($inf, $chain) = @ARGV;
open (IF, "<$inf") || die "Cno $inf:$!.\n";



$reading = 0;

(! defined $chain ) && ($chain   = "");

while ( <IF> ) {
    if ( /RESIDUE AA STRUCTURE/ ) {
	$reading = 1;
    } elsif ($reading ) {
	$pdbid = substr $_, 6, 4;
	$cc = substr $_, 11, 1;
	next if ( $chain && $cc ne $chain);
	$aa = substr $_, 13, 1;
	$acc =  substr $_, 35, 3;
	#next if ( $aa eq "!" );
	print " $pdbid   $aa   $acc\n";
    }
}

exit;
