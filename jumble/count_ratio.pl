#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: count_ratio.pl <table_file> \n";


open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";
$let = $grt = $eq = 0;
while ( <NAMES> ) {
   
    if ( /\w/ ) {
    
	chomp;
	@aux = split ' ';
	    if (  $aux[2] < $aux[3] ) {
		$let ++;
	    } elsif  ( $aux[2] > $aux[3] ){
		$grt ++;
	    } else {
		$eq ++;
	    }
    } 
    
}

print "col1 less than coll2: $let\n";
print "col1 equal  coll2: $eq\n";
print "col1 greater than coll2: $grt\n";

