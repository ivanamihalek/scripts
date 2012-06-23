#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[2] ||
    die "Usage: random_seq_selection.pl <msf_file> <query> <fractn>.\n"; 

$msf =  $ARGV[0]; 
$query = $ARGV[1];
$frac = $ARGV[2];

@names = ();

open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";


while ( <MSF> ) {
    if ( /Name/) {
	@aux = split;
	$name =  $aux[1];
	if ( $name eq $query || rand() < $frac ) {
	    push @names, $name;
	    print;
	}
    } else {
	print;
    }
    last if ( /\/\// );
    
}




while ( <MSF>) {
    if ( /\w/ ) {
	foreach $name ( @names) {
	    if ( $_ =~ /^$name\s/ ||  $_ =~ /\s$name\s/) {
		print;
		last;
	    }
	}
	
    } else {
	print;
    }
};
