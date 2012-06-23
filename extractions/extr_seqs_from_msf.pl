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
	foreach $name ( @names) {
	    $nameq = quotemeta $name;
	    if ( $_ =~ /^$nameq\s/ ||  $_ =~ /\s$nameq\s/) {
		chomp;
		print;
		print "\n"; # sometimes get grabage @ the eol - from cw?
		last;
	    }
	}
	
    } else {
	chomp;
	print;
	print "\n";
    }
} while ( <MSF>);
