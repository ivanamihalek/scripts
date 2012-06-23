#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[2]  ||
    die "Usage: splice_gaps.pl <msffile> <splice position> <number of gaps>\n"; 


$home = `pwd`;
chomp $home;
($name, $splice_pos, $nr_gaps)  = @ARGV  ;

@names = ();

open ( MSF, "<$name" ) ||
    die "Cno: $name  $!\n";
	

while ( <MSF>) {
    last if ( /\/\// );
    last if ( /CLUSTAL FORMAT for T-COFFEE/ );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $name = $aux[0];
    if ( defined $sequence{$name} ){
	$sequence{$name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$sequence{$name}  = join ('', @aux[1 .. $#aux]);
	push @names, $name;
    }
}


close MSF;
$gaps = "";
for  ( 1 ..$nr_gaps ) {
    $gaps .=  ".";
}


foreach $name ( @names ) {
    substr ( $sequence{$name}, $splice_pos, 0) = $gaps;
}
 
 




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
