#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$ignore = <>;
$ignore = "";


$group_ctr = 0;
$seqctr=-1;
while ( <> ) {
    if ( ! /\S/ )  {
	$group_ctr ++;
	$seqctr=-1;
	next;
    }
    chomp;
    @aux = split;
    $seqctr++;
    if ( !$group_ctr) {
	$names[$seqctr] = $aux[0];
	shift @aux;
    }
    $substr = join '', @aux;
    $substr =~ s/\-/\./g;
    if ( defined $seq{$names[$seqctr]}  )  {
	$seq{$names[$seqctr]} .= $substr;
    } else {
	$seq{$names[$seqctr]}  = $substr;
    }
    

}



$seqlen = length $seq{$names[0]};
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name ( @names  ) {
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($seq{$name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($seq{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
