#! /usr/bin/perl -w
use IO::Handle;         #autoflush

$ctr = 0;
$ctr_bad = 0;

$name = "problematic";
open (OPTR, ">$name") ||
	die "Cno $name: $! \n";


while ( <> ) {
    chomp;
    @aux  = split;
    #$name = $aux[0]."/".$aux[0].".pdb";
    $name = substr ($aux[0],0,4).".pdb";
    open (FPTR, "<$name") ||
	die "Cno $name: $! \n";
    $ctr++;
    while ( <FPTR>) {
	next if ( ! /^ATOM/ );
	@aux = split '';
	if ( $aux[26] =~ /\S/ ) {
	    $ctr_bad++;
	    print OPTR "$name \n";
	    print OPTR "($ctr_bad out of $ctr)   ";
	    print OPTR ;
	    OPTR -> autoflush(1);
	    last;
	}
    }
    close FPTR;
}
