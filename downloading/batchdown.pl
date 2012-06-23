#! /usr/gnu/bin/perl -w -I/home/i/imihalek/perlscr
#perl -I/home/protean2/LSETtools/utils ~/perlscr/batchdown.pl

use Simple;		# these 2 packages for HTML support

defined $ARGV[0] ||
    die "Usage: batchdown.pl <gi_list_file> [-f]\n"; 

$cmdstr_base = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=text&db=protein&dopt=genpept&dispmax=1000";
#$cmdstr_base = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=text&db=nucleotide&dopt=GenBank&dispmax=1000";
$table = $ARGV[0]; 
$fasta = defined  $ARGV[1];

open ( GI, "<$table") ||
    die "Cno $table: $!\n";

$ctr = 0;
$cmdstr = $cmdstr_base;
while ( <GI> ) {
    
    chomp;
    @aux = split;
    if ( ! ($aux[0] =~ /\D/) ) {
	$ctr++;
	if ( $ctr > 10 ) {
	    fetch_and_out ();
	    $ctr = 1;
	    $cmdstr = $cmdstr_base;
	}
	$cmdstr .= "&uid=$aux[0]";
    }
}

( $ctr <= 10 ) && fetch_and_out();


sub fetch_and_out () {
    $ret =  get  $cmdstr;
    $on = 0;
    @lines = split '\n', $ret;
    $gi = 0;
    foreach $line (@lines) {
	if ( $line =~ /GI\:(\d+)/ ) {
	    $gi = $1;
	} elsif ( $line =~ /ORIGIN/) {
	    $on = 1;
	    print "> $gi\n";
	    if ( $gi ==  0 ) {
		print $ret;
		exit;
	    }
	} elsif ( $line =~ /^\/\// ) {
	    $on = 0;
	    $gi = 0;
	} elsif ( $on) {
	    $line =~ s/\d//g;
	    $line =~ s/\s//g;
	    print "$line\n";
	}
    }
}
