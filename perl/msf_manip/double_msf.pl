#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# double each sequence in the alignment (beginning-to-end)



 
defined $ARGV[0]  ||
    die "Usage: double_msf.pl  <msf_file>.\n"; 

$msf   =  $ARGV[0];
open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

# read in the msf file:
while ( <MSF> ) {
    last if ( /\/\//);
}

%sequence = ();
do {
    if ( /\w/ ) {
	@aux = split;
	$name = $aux[0];
	$aux_str = join ('', @aux[1 .. $#aux] );
	if ( defined $sequence{$name} ) {
	    $sequence{$name} .= $aux_str;
	} else {
	    $sequence{$name}  = $aux_str;
	}
		
    } 
} while ( <MSF>);

#double each sequence
foreach $name ( keys %sequence  ) {
    $sequence{$name} .= $sequence{$name};
}

# output
$seqlen = length $sequence{$name};
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
	printf "%-15s", $name;
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
