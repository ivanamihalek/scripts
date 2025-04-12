#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined $ARGV[0] ||
    die "usage: hmmparse.pl <base_name>.\n";

$base_name = $ARGV[0];

open (HMM, "<$base_name.hmmsearch" ) ||
    die "Cno base_name.hmmsearch: $!.\n";

while ( <HMM> ) {
    last if ( /Alignments of top-scoring domains/ );
}


$ctr = -1;
while ( <HMM> ) {
    if ( /Histogram/ ) {
	last;
    } elsif ( /^\S/ ) {
	$ctr++;
	if ( /\|/ ) {
	    @aux = split '\|';
	    $seq_name[$ctr] = $aux[1];
	} else {
	    @aux = split '\:';
	    $seq_name[$ctr] = $aux[0];
	}
	print "$seq_name[$ctr]\n";
	#@aux2 = split ' ', $aux[ $#aux];
	#last if ( $aux2[$#aux2] > 1.0e-5);

	if  ( $aux[ $#aux] =~ /domain (\d+) of (\d+)/  && $2 > 1) {
	    $seq_name[$ctr] .= "_$1";
	}
	$seq[$ctr] = "";
    } elsif( substr ($_, 0, 15) =~  /\S/ ) {
	@aux = split ;
	$seq[$ctr] .= $aux[2];
    } 
}
$max_ctr = $ctr;
$name = "";

close HMM;
print "number of seq:  $ctr\n"; 


foreach  $ctr ( 0 .. $max_ctr ){ 
    $seq[$ctr] =~ s/\-//g;
    $seq[$ctr] = uc $seq[$ctr];
}

$name = $base_name.".fasta";
open ( FP, ">$name" ) ||
    die  "Cno $name: $! \n";

foreach  $ctr ( 0 .. $max_ctr ){ 
    if (!  defined $found{  $seq[$ctr] } ) {
	$found{ $seq[$ctr] } = 1;
	(  $seq[$ctr])  ||
	    die "empty $seq_name\n";
	printf  FP "> %-20s \n%s \n", $seq_name[$ctr],  $seq[$ctr];
    } else {
	print "$ctr:  duplicate\n";
    }
}

close FP;
