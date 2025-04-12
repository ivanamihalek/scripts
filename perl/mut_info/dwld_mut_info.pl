#! /usr/gnu/bin/perl -w
# Ivana, Dec 2001
# make pdbfiles directory  and download the pdbfiles
# for proteins with names piped in


use Simple;		#HTML support

$failctr = 0;
while ( <>) {
    next if ( ! /\w/ );
    chomp;
    
    $retstring = get $_ || "";

    $retstring =~ /\<H1\>(.+)\<\/H1\>/i;
    $title = $1;

    $retstring =~ s/\<a HREF\=\"cgi\-bin\/PMD\/PMDentry\.pl\.cgi\?(\w+)\"\>(\w+)\<\/A\>/$1  $2/gi;
    $retstring =~ s/\<.+\>//g;

    if ( ! $retstring ) {
	print "retrieval failure\n";
	$failctr++;
    } else {
	print "*****************************************\n";
	print "*****************************************\n";
	print "      $title \n";
	print "*****************************************\n";
	print $retstring;
    }
}



print "no of failures $failctr \n";
