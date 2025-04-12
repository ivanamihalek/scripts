#! /usr/gnu/bin/perl -w
#perl -I/home/protean2/LSETtools/utils ~/perlscr/termdown.pl

use Simple;		# these 2 packages for HTML support

defined $ARGV[0] ||
    die "Usage: perl -I/home/protean2/LSETtools/utils batchdown.pl <gi_list_file> \n"; 

$table = $ARGV[0]; 


open ( GI, "<$table") ||
    die "Cno $table: $!\n";

while ( <GI> ) {
    chomp;
    @aux = split;
    
	$cmdstr = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&db=protein&doptcmdl=GenPept";
	$cmdstr .= "&term=\"$aux[0]\"[PACC]";
    print  $cmdstr, "\n";
    $retval = get $cmdstr;
    @lines = split  "\n", $retval;
    $started = 0;
    foreach $line (@lines ) {
        if ( !$started && $line =~ /LOCUS/ ) {
	    $started = 1;
	}
	if ( $started ) {
	    $line =~ s/\<.*\>//g;
	    print $line , "\n";
	    last if  ($line =~ /^\/\// );
	}
    }
    print "\n";
}

