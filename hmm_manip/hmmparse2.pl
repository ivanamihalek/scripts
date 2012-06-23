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
$sub_name = "blah";

while ( <HMM> ) {
    if ( /^\S/) {
	@aux = split '\:';

	$ctr++;
	$name[$ctr] = $aux[0];
	if  (/domain (\d+) of (\d+)/  && $2 > 1) {
	    $name[$ctr] .= "_$1";
	}
	$seq[$ctr] = "";
	$sub_name = substr $name[$ctr], 0, 10;
    } elsif( /$sub_name/ ) {
	@aux = split ;
	$seq[$ctr] .= $aux[2];
    }
}
$max_ctr = $ctr;
$name = "";

close HMM;

foreach  $ctr ( 0 .. $max_ctr ){ 
    $seq[$ctr] =~ s/\-//g;
    $seq[$ctr] = uc $seq[$ctr];
}
foreach  $ctr ( 0 .. $max_ctr ){ 
    if ( ! ( ($ctr) % 1000) ) {
	if ( $name ) {
	    close FP;
	}
	$name = $base_name.".$ctr".".fasta";
	open ( FP, ">$name" ) ||
	   die  "Cno $name: $! \n";
    }
    if (!  defined $found{  $seq[$ctr] } ) {
	$found{ $seq[$ctr] } = 1;
	(  $seq[$ctr])  ||
	    die "empty $gi\n";
	printf  FP "> %-20s \n%s \n", $name[$ctr],  $seq[$ctr];
    }
}

close FP;
