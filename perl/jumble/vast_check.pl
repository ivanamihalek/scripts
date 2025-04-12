#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use IO::Handle;         #autoflush
# FH -> autoflush(1);
use Simple;		#HTML support


while ( <> ) {
    next if ( ! /\S/ );
    chomp;
    $name = $_;
    print "$name\n";
    $searchstr =  "http://www.ncbi.nlm.nih.gov/Structure/mmdb/mmdbsrv.cgi?uid=$name";
    $retval ="" || get $searchstr ;
    if ( $retval) {
	if ( $retval =~ /not found/i ) {
	    print "not found.\n"; 
	    next;
	}
	$retval =~ s/\<.+?\>/ /g;
	$retval =~ s/\&gt\;/\>/g;
	print;
    }
    exit;
}
