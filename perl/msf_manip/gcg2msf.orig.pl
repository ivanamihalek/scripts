#! /usr/gnu/bin/perl -w

$ctr = 0;
while (<>) {
    @aux = split;
    $name = "";
    foreach $i (0.. $#aux) {
	if (length $aux[$i] < 10 ) {
	    $name .= $aux[$i];
	} else {
	    $aux[$i] =~ s/-/\./g;
	    $aux[$i] =~ s/\*//g;
	    $sequence[$ctr] = $aux[$i];
	    $names[$ctr] = $name;
	    $ctr ++;
	    $seqlen = length $aux[$i];
	}
    }
}
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $ctr (0 .. $#names ) {
    printf (" Name: %-20s   Len: %d\n", $names[$ctr], $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $ctr (0 .. $#names ) {
	printf "%-20s", $names[$ctr];
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($sequence[$ctr], $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($sequence[$ctr], $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
