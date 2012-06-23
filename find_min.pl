#! /usr/gnu/bin/perl -w

while (<>) {
    chomp;
    open ( INFILE, "<$_" ) || 
	die "cno $_\n";
    $name =$_; 
    $min =1.0;
    $min_rank = -1;
    while ( <INFILE>) {
	next if /RANK/;
	@aux = split;
	if ( $aux[9] < $min ) {
	    $min = $aux[9];
	    $min_rank = $aux[0];
	}
    }
    close INFILE;

    print "   $name:  $min  \@  $min_rank \n"; 

}
