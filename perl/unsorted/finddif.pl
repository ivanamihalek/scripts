#! /usr/gnu/bin/perl
# find proteins in which two blastp
# files differ -- a clumsy hack
# Ivana, Dec 2001
$file1 = "tmp.blastp";
$file2 = "1g6oA.blastp"; 

open ( FILE1, "<$file1") 
|| die "open fail $file1"; 

while ( <FILE1>) {
    if ( /\|(\w*).*\|/) {
	last if (/>ref/);
	next if ( length($1) == 0);
	open ( FILE2, "<$file2") 
	    || die "open fail $file2";
	$found = 0;
	$line = $_;
	while ( $line2 = <FILE2>) {
	    last if ( />ref/);
	    if ( $line2 =~ $1 ) {
		$found = 1;
		last;
	    }
	}
	if (! $found ){
	    print $line;
	}
	close FILE2;
	
    }
}

  close FILE1; 
