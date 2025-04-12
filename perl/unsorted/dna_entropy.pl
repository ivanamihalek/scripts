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

open ( TMP, ">tmp" ) ||
    die "cno tmp: $!\n"; 

$dna_seq_length = length  $seqs{$seq_name};
$prot_seq_length = $dna_seq_length/3;

print " $dna_seq_length  $prot_seq_length\n";


for $pos ( 0 ..  $prot_seq_length-1) {
    %frequency = ();
    foreach $seq ( values  %seqs ) {
	$triplet = substr $seq, 3*$pos, 3;

	if ( defined $frequency{$triplet} ) {
	    $frequency{$triplet} +=  1;
	} else {
	    $frequency{$triplet}  =  1;
	}
    }

    $entropy = 0;
    foreach $triplet ( keys %frequency) {
	$fr =  $frequency{$triplet}/$num_seq;
	$entropy -= $fr*log($fr);
    }
    printf   TMP "%8.3f %4d     ", $entropy, $pos+1;
    foreach $triplet ( keys %frequency) {
	printf   TMP "%s   ", $triplet;
    }
    print   TMP "\n";
}
close TMP;

print `sort -g tmp`;

`rm tmp`;
