#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[0] &&  defined $ARGV[1] ||
    die "Usage: extr_seqs_from_msf.pl <name_list> <msf_file>.\n"; 
$list = $ARGV[0]; 
$msf =  $ARGV[1]; 
open ( LIST, "<$list") ||
    die "Cno $list: $!\n";


@names = ();
while ( <LIST>) {
    if ( /\w/ ) {
	@aux = split;
	push @names, $aux[0]; 
    }
}
close LIST;

open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

while ( <MSF> ) {
    last if ( /Name/);
    print;
}

do {
    if ( /\w/ ) {
	$skip = 0;
	foreach $name ( @names) {
	    if ( $_ =~ /^$name\s/ ||  $_ =~ /\s$name\s/) {
		$skip = 1;
		last;
	    }
	}
	($skip ) || print;
	
    } else {
	print;
    }
} while ( <MSF>);
