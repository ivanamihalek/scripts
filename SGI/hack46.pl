#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
$ctr = 0;
while ( <> ) {
    if ( /max/ ) {
	chomp;
	@aux = split;
	$new = $aux[2];
	while ( <> ) {
	    if ( /max/ ) {
		chomp;
		@aux = split;
		$old = $aux[2];
		last;
	    }
	}
	$ctr++;
	printf "%5d  %10.4lf \n", $ctr, $new-$old;
    }
}
