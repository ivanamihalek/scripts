#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: msf2_mutate.pl <msffile> <mutation_file>\n"; 


$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;

open ( MSF, "<$name" ) ||
    die "Cno: $name  $!\n";
	

@names = ();
while ( <MSF>) {
    last if ( /\/\// );
    last if ( /CLUSTAL FORMAT for T-COFFEE/ );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $name = $aux[0];
    if ( defined $seq{$name} ){
	$seq{$name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seq{$name}  = join ('', @aux[1 .. $#aux]);
	push @names, $name;
    }
}

close MSF;


	
$name = $ARGV[1] ;

open ( MUT, "<$name" ) ||
    die "Cno: $name  $!\n";
	

while ( <MUT>) {
    next if ( ! (/\S/) );
    chomp;
    @aux = split;
    $name = $aux[1];
    $pos =   $aux[2];
    $from = $aux[3];
    $to   = $aux[4];
    #print "$name  $from ", substr ($seq{$name}, $pos-1, 1), "   $to\n";
    substr ($seq{$name}, $pos-1, 1) = $to;
}
close MUT;

$from = "";


$seqlen = length $seq{$name};

print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach  $name ( @names) {
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 > $seqlen ) {
		$patch_length = $seqlen -($j+$k*10);
		printf ("%-10s ",   substr ($seq{$name}, $j+$k*10, $patch_length ));
		last;
	    } else {
		printf ("%-10s ",   substr ($seq{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
