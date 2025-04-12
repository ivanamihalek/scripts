#!/usr/gnu/bin/perl -w -I/home/i/imihalek/perlscr
use IO::Handle;         #autoflush
# FH -> autoflush(1);

use Simple;		#HTML support

defined $ARGV[0] ||
    die "Usage: short_fetch.pl <gifile> .\n";

$gifile = $ARGV[0];
open (GI, "<$gifile") ||
    die "Cno $gifile:$!.\n";

$database = "protein";
$rettype = "fasta";
#$rettype = "acc";
$retmode = "text";

$htmlstring  = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi";
$htmlstring .= "?db=$database";




while ( <GI> ){
    chomp;
    @aux = split;
    if (!defined $gi ) {
	$gi = $aux[0];
	$htmlstring .= "&id=$gi";
    } else {
	$gi = $aux[0];
	$htmlstring .= ",$gi";
    }

}

$htmlstring .= "&rettype=$rettype&retmode=$retmode";
#print $htmlstring,"\n"; exit;


$retfile = get $htmlstring || "";
#print $retfile;


@lines  = split '\n',$retfile ;
$ctr = 0;
foreach $line ( @lines ) {
    if ( $line =~ /\>/ ) {
	$ctr++;
	$line =~ /\|(.+?)\|/;
	print "$ctr: $1\n";
	$line =~ /\>(.+\|)/;
	$aux = quotemeta $1;
	$aux3 = $1;
	if ( $line =~ /$aux\s*(.+)/ ) {
	    $aux2 = $1;
	    if ( $aux2 =~ /(.+)(\[.+\])/ ) {
		print "$1 $2 \n";
	    } else {
		print "$aux2\n";
	    }
	}
	print "$aux3\n\n";

   }
}




