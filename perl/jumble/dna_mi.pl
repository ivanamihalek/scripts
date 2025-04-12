#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: dna_entropy.pl <msffile> \n"; 


$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;
$num_seq = 0;

###############################################################

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
    $seq_name = $aux[0];
    if ( defined $seqs{$seq_name} ){
	$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$num_seq ++;
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;

$dna_seq_length = length  $seqs{$seq_name};
$prot_seq_length = $dna_seq_length/3;

##print " $dna_seq_length  $prot_seq_length\n";


###############################################################
$simulation = 1;
$no_rounds = $prot_seq_length*10;

if ( $simulation ) {
    $avg = 0;
    $avg_sq = 0;
    for $round ( 1 .. $no_rounds) {
	$pos1 = rand ( $prot_seq_length );
	$pos2 = rand ( $prot_seq_length );
	%frequency_1 = ();
	%frequency_2 = ();
	%frequency_pair = ();
	foreach $seq ( values  %seqs ) {
	    
	    $codon1 = substr $seq, 3*$pos1, 1;
	    $codon2 = substr $seq, 3*$pos2+1, 1;
	    $pair = $codon1.$codon2;

	    if ( defined $frequency_1{$codon1} ) {
		$frequency_1{$codon1} +=  1;
	    } else {
		$frequency_1{$codon1}  =  1;
	    }

	    if ( defined $frequency_2{$codon2} ) {
		$frequency_2{$codon2} +=  1;
	    } else {
		$frequency_2{$codon2}  =  1;
	    }

	    if ( defined $frequency_pair{$pair} ) {
		$frequency_pair{$pair} +=  1;
	    } else {
		$frequency_pair{$pair}  =  1;
	    }
	}

	$mi = 0;
	foreach $pair ( keys %frequency_pair) {
	    $fr_pair =  $frequency_pair{$pair}/$num_seq;
	    ($codon1, $codon2) = split '', $pair;
	    $fr_1 =  $frequency_1{$codon1}/$num_seq;
	    $fr_2 =  $frequency_2{$codon2}/$num_seq;
	
	    $mi += $fr_pair*log ( $fr_pair/($fr_1*$fr_2));
	}
	$avg += $mi;
	$avg_sq += $mi*$mi;

    }
    $avg /= $no_rounds;
    $avg_sq /= $no_rounds;
    $stdev = sqrt ( $avg_sq - $avg*$avg);
    #printf "%8.3f   %8.3f \n", $avg, $stdev;
 }
###############################################################
open ( TMP, ">tmp" ) ||
    die "cno tmp: $!\n"; 


for $pos ( 0 ..  $prot_seq_length-1) {

    %frequency_1 = ();
    %frequency_2 = ();
    %frequency_pair = ();
    foreach $seq ( values  %seqs ) {

	$codon1 = substr $seq, 3*$pos, 1;
	$codon2 = substr $seq, 3*$pos+1, 1;
	$pair = $codon1.$codon2;

	if ( defined $frequency_1{$codon1} ) {
	    $frequency_1{$codon1} +=  1;
	} else {
	    $frequency_1{$codon1}  =  1;
	}

	if ( defined $frequency_2{$codon2} ) {
	    $frequency_2{$codon2} +=  1;
	} else {
	    $frequency_2{$codon2}  =  1;
	}

	if ( defined $frequency_pair{$pair} ) {
	    $frequency_pair{$pair} +=  1;
	} else {
	    $frequency_pair{$pair}  =  1;
	}
    }

    $mi = 0;
    foreach $pair ( keys %frequency_pair) {
	$fr_pair =  $frequency_pair{$pair}/$num_seq;
	($codon1, $codon2) = split '', $pair;
	$fr_1 =  $frequency_1{$codon1}/$num_seq;
	$fr_2 =  $frequency_2{$codon2}/$num_seq;
	
	$mi += $fr_pair*log ( $fr_pair/($fr_1*$fr_2));
    }

    $z = ($mi-$avg)/$stdev;
    printf    TMP  "%8.3f   %4d   %8.3f \n", $mi,  $pos+1, $z; 
=pod
    foreach $triplet ( keys %frequency) {
	printf   TMP "%s   ", $triplet;
    }
    print   TMP "\n"; 
=cut
}
close TMP;

print `sort -gr tmp`;

`rm tmp`;

