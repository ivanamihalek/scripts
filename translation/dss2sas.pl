#!/usr/bin/perl -w

(@ARGV  ) ||
    die "Usage: $0 <dssp file> \n";


($inf) = @ARGV;
open (IF, "<$inf") || die "Cno $inf:$!.\n";



$reading = 0;
$chain   = "";

while ( <IF> ) {
    if ( /RESIDUE AA STRUCTURE/ ) {
	$reading = 1;
    } elsif ($reading ) {
	$pdbid = substr $_, 6, 4;
	$chain = substr $_, 11, 1;
	$aa = substr $_, 13, 1;
	$acc =  substr $_, 35, 3;
	next if ( $aa eq "!" );
	print " $pdbid   $aa   $acc\n";
    }
}

exit;
