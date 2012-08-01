#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined $ARGV[1] || 
    die "Usage: model_renumber.pl  <pdb file> <starting model no>.\n";

($pdbfile, $start ) = @ARGV;

open (IF, "<$pdbfile") 
    || die "Co $pdbfile: $!.\n";

$ctr = $start;
while ( <IF> ) {

    if ( /^MODEL / ) {
	print "MODEL        $ctr\n";
	$ctr ++;
    } else {
	print;
    }
}

close IF;
