#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: msf2fasta.pl <msffile> \n"; 


$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;
####################################################
# input
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
    $seq_name = $aux[0];
    if ( defined $sequence{$seq_name} ){
	$sequence{$seq_name} .= lc join ('', @aux[1 .. $#aux]);
    } else { 
	$sequence{$seq_name}  = lc join ('', @aux[1 .. $#aux]);
	push @names, $seq_name;
    }
}

close MSF;



####################################################
# construct the translation array
%values = ('a', 0, 'c', 1, 't', 2, ,'g', 3);

foreach $i ( keys %values ) {
    foreach $j ( keys %values ) {
	foreach $k ( keys %values ) {
	    $codon = $i.$j.$k;
	    $numerical = 16*$values{$i} +4*$values{$j}+$values{$k};
	    ( $numerical== 62 ) && ( $numerical = -30); # these are not printable
	    ( $numerical== 63 ) && ( $numerical = -29);
	    $character = chr (65+$numerical);
	    #print "$codon      $numerical   $character\n";
	    $hack_translation{$codon} = $character;
	}
    }
}



####################################################
# translation
foreach $seq_name ( @names  ) {
    $seq =  $sequence{$seq_name};
    $seqlen = length $seq;
    ( !($seqlen % 3) ) || die "the length of $seq_name ($seqlen) not divisible by 3 .\n";	
    $sequence2{$seq_name} = ""; 
    for $codon_ctr ( 0 .. ($seqlen/3-1) ) {
	$codon = substr $seq, $codon_ctr*3, 3;
	if ( $codon eq "..." ) {
	    $sequence2{$seq_name} .= "." ;
	} else {
	    $sequence2{$seq_name} .= $hack_translation{$codon};
	}
    }
}

####################################################
# output
$seqlen = length $sequence2{$seq_name};
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
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($sequence2{$name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($sequence2{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
 


