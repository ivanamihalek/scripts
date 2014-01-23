#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: afa2msf.pl  <afa_file>.\n"; 

$fasta =  $ARGV[0]; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {

	$name = $1;
	push @names,$name;
	$sequence{$name} = "";
    } else  {
	#s/\-/\./g;
	#s/\#/\./g;
       #seaview will count '.' as a residue if the file is the .afa format, but if the file is the .msf, the seaview the '.' will not be count. 
       #here I change all '.' to '-' is for the subsequent program, patcher.pl or find_closest_replace.pl, they will take .msf file as input
       #output .afa file, so if we do not use '-' to substitute '.', the output (i.e .afa file) will contain '.' and when we view this .afa
       #file using seaview, the seaview will count '.' as a residue so the counting number will different from msf file 
        s/\./\-/g;     
        s/\#/\-/g;
	s/\s//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close FASTA;

$longest_name = -1;
foreach $name (@names) {
#print "$name->:";
#$tmp=length $sequence{$name};
#print "$tmp\n";
    if ( length $name > $longest_name ) {
	$longest_name = length $name 
    }
}
$longest_name ++;
( $longest_name < 20 ) && ($longest_name=20);
$seqlen = length $sequence{$name};
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: N    Check:  9554   .. \n\n",$seqlen) ;

$format = " Name: %-$longest_name"."s   Len: %5d   Check: 9554   Weight: 1.00\n";

foreach $name ( @names  ) {
    printf ( $format, $name, $seqlen);
}
printf "\n//\n\n\n\n";

$format = "%-$longest_name"."s";
for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name ( @names  ) {
	printf $format, $name;
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
