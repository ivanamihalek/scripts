#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
sub output;

$id = "-";
$ac = "-";
$embl1 = "-";
$embl2 = "-";
while ( <> ) {
    $linectr ++;
    if ( /^ID/ ) {
	@aux = split;
	$id = $aux[1];
    } elsif (/^AC/ ) {
	@aux = split;
	$ac = $aux[1];
	$ac =~ s/\;//g;
    } elsif (/^DR/  && /EMBL/) {
	@aux = split '\;';
	$embl1 = $aux[1];
	$embl1 =~ s/\s//g;
	$embl2 = $aux[2];
	$embl2 =~ s/\s//g;
    } elsif ( /^\/\// ) {
	printf "%10s   %10s    %10s   %10s\n", $ac, $id, $embl1, $embl2;
	$id = "-";
	$ac = "-";
	$embl1 = "-";
	$embl2 = "-";
   } 
}

