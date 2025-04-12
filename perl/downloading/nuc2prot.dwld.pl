#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use IO::Handle;         #autoflush
# FH -> autoflush(1);

use Simple;		#HTML support

$database = "nucleotide";
#$rettype = "fasta";
$rettype = "gb"; #GenBank
#$rettype = "acc";
$retmode = "text";

$htmlstring  = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi";
$htmlstring .= "?db=$database";


while ( <> ) {
    chomp;
    @aux = split;
    $gi = $aux[0];
    $database = "nucleotide";
    $rettype = "gb"; #GenBank
    $retmode = "text";
    $htmlstring  = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi";
    $htmlstring .= "?db=$database";
    $htmlstring .= "&id=$gi";
    $htmlstring .= "&rettype=$rettype&retmode=$retmode";
    $retfile = get $htmlstring || "";
    ( $retfile ) ||
	die "No ret.\n";
    $retfile =~ /\/db_xref\=\"GI\:(.+)\"/;
    if ( defined $1 ) {
	$newgi = $1;
	$database = "protein";
	$rettype = "fasta"; #GenBank
	$retmode = "text";
	$htmlstring  = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi";
	$htmlstring .= "?db=$database";
	$htmlstring .= "&id=$newgi";
	$htmlstring .= "&rettype=$rettype&retmode=$retmode";
	$retfile = get $htmlstring || "";
	( $retfile ) ||
	    die "No ret.\n";
	print $retfile;
	
    } else {
	print "\tprotein id not found\n";
    }

}

