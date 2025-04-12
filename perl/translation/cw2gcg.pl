#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: cw2gcg.pl <msffile> \n"; 


$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;

@names = ();

open ( MSF, "<$name" ) ||
    die "Cno: $name  $!\n";
	
while ( <MSF>) {
    next if ( ! (/\w/) );
    next if (  (/CLUSTAL/) );
    chomp;
    @aux = split;
    $name = $aux[0];
    if ( defined $sequence{$name} ){
	$sequence{$name} .= $aux[1];
    } else { 
	push @names,$name;
	$sequence{$name}  = $aux[1];
    }
}

close MSF;

foreach $name ( keys %sequence ) {
    $sequence{$name} =~ s/\-/\./g;
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
