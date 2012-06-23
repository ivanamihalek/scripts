#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: afa2msf.pl  <joy file>.\n"; 

$fasta =  $ARGV[0]; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

$crap = "";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {

	($crap, $name) =  split ';', $1;
	 $line = <FASTA>;
	@aux = split '\:', $line;
	$chain = $aux[3];
	$name = (lc $name);
	#( defined $chain  && $chain ne " "  ) || ( $chain = "_" );
       ( defined $chain ) && ( $name .= $chain);
	push @names,$name;
	$sequence{$name} = "";
	
    } else  {
	s/\-/\./g;
	s/\#/\./g;
	s/\//\./g;
	s/\*//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close FASTA;


$seqlen = length $sequence{$name};
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: N    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name ( @names  ) {
	printf "%-20s", $name;
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
