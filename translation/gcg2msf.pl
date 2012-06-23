#! /usr/gnu/bin/perl -w


while (<>) {
    chomp;
    if ( /\w/ ) {
	undef @aux;
	@aux = split;
	$name = $aux[0];
	next if ( $name eq "CLUSTAL" );
	if ( ! defined ($sequence{$name} ) ){
	    $sequence{$name} = "";
	}
	foreach $i (1.. $#aux) {
	    $sequence{$name} .= $aux[$i];
	}
    }
}

foreach $name ( keys %sequence  ) {
    $sequence{$name} =~ s/\-/\./g;
    $seqlen = length $sequence{$name};
    #printf "%-20s", $name;
    #print $seqlen, "\n";
    ##print $sequence{$name}, "\n\n\n\n";
}

print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( keys %sequence  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name ( keys %sequence  ) {
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
