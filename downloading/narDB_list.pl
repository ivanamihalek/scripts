#!/usr/bin/perl -w -I/home/ivanam/perlscr
use IO::Handle;         #autoflush
# FH -> autoflush(1);

use Simple;		#HTML support



$base_htmlstring  = "http://www.oxfordjournals.org/nar/database";



for $cat ( 1 .. 15) {

    $htmlstring = "$base_htmlstring/cat/$cat";
    #print $htmlstring,"\n"; exit;

    $retfile = get $htmlstring || "";
    @lines = split "\n", $retfile;

    foreach $line (@lines ) {
	($line =~ /subcat\/(\d+\/\d+)/) || next;
	$subcat =  $1;

	$htmlstring = "$base_htmlstring/subcat/$subcat";
	$retfile = get $htmlstring || "";
	@sublines = split "\n", $retfile;

	@summary = ();
	foreach $subline (@sublines) {
	    ($subline =~ /listpaper/) || next;
	    ($subline =~ m/exo/i || $subline =~ m/intro/i ) || next;
	    push @summary, $subline;
	    
	}

	@summary || next;

	print $line, "\n";
	foreach $subline (@summary ) {
	    print "\t\t *** $subline\n";
	}
    }


}





