#!/usr/bin/perl -w

(@ARGV  ) ||
    die "Usage: $0 <dssp file> \n";


($inf) = @ARGV;
open (IF, "<$inf") || die "Cno $inf:$!.\n";

$seqname = $inf;
$seqname =~ s/\.dssp//;


print ">$seqname\n";
$reading = 0;
$sse_old= "blah";
while ( <IF> ) {
    if ( /RESIDUE AA STRUCTURE/ ) {
	$reading = 1;
    } elsif ($reading ) {
	$sse = substr $_, 16, 1;
	if ( $sse =~ /[HE]/ && $sse ne $sse_old ) {
	    print "$sse";
	}
	$sse_old = $sse;
    }
}
print "\n";

exit;
