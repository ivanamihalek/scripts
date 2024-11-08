#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
sub output;

$id = "-";
$iv = "-";
$pa = "-";
$linectr = 0;
while ( <> ) {
    $linectr ++;
    if ( /^ID/ ) {
	@aux = split;
	$id = $aux[1];
	$startline = $linectr;
    } elsif ( /^IV/ ) {
	@aux = split;
	$iv = $aux[1];
    } elsif ( /^PA/ ) {
	@aux = split;
	$pa = $aux[1];
    } elsif ( /^\/\// ) {
	printf "%10s     %10s  %10d   %10d\n", $id, $iv, $startline, $linectr;
	$id = "-";
	$iv = "-";
	$pa = "-";
   } 
}

