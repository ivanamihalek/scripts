#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# use output of var_ID descr to find typical kwds showing up in descr od the sequence

$ctr = 0;
while ( <> ) {
    $ctr ++;
    if ( ! ( ($ctr-2) % 3)  ) {
	#print; 
	chomp;
	$descr = $_;
	#try to standardize the descr
	$descr =~ s/\.//g;
	# get rid of brackets
	$descr =~ s/\(.*\)//g;
	# get rid of whitespce
	if ( $descr ) {
	    @aux = split '', $descr;
	    do {
		$tmp = shift @aux;
	    } while ( $tmp =~ /\s/ );
	    unshift @aux, $tmp;
	    $descr = join '', @aux;
	    $descr =~ s/\s\s/ /g;
	    $descr =~ s/"-"/ /g;
	    if ( defined $found{$descr} ) {
		$found{$descr} ++;
	    } else {
		$found{$descr} = 1;
	    }
	}
    }
}


foreach $kwd ( keys %found ) {
    ($kwd )  ||  ($kwd = "not found");
    print "$kwd     \n";   
}

