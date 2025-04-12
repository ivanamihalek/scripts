#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$reading = 0;
$descr   = "";
while ( <> ) {
    if ( !/\S/ ) {
	$reading = 0;
    } else {
	if ( ! $reading ) {
	    $reading = 1;
	    $descr   = "";
	} else {
	    if ( /^gi\|(\d+)\|/ ) {
		$gi = $1;
		if ( $descr ) {
		    process_descr();
		}
	    } else {
		$descr .= $_;
	    }
	}
    }
}




sub process_descr () {

#		if ( $descr =~ /phosphorylase/i &&  $descr =~ /purine/i) {
#		if ( $descr =~ /triosephosphate isomerase/i ) {

    if ( $descr =~ /pyr/i ) {
	$keyword = "pyr";
    } elsif ( $descr =~ /hypo/i ) {
	$keyword = "hyp";
    } else {
	$keyword = "x";
    }

   
    $descr =~ /\[(.+)\]/ ;
    $spec = $1;
    if ( ! defined $spec ) {
	$spec = "x";
    }
    @aux = split ' ', $spec;
    $name = uc (substr $aux[0], 0, 3);
    if ( defined $aux[1] ) {
	$name .= "_". uc (substr $aux[1], 0, 3);
    }
    $name .= "_".$gi;
    $name .= "_".$keyword;

    @aux = split '\n', $descr;
    print "$gi   $name  ";
    print "$aux[0]\n";

}
