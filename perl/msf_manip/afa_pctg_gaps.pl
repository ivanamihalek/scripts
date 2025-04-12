#! /usr/bin/perl -w

sub process_seq ();



defined $ARGV[0]  ||
    die "Usage: afa_pctg_gaps  <afa_file>.\n"; 

$fasta =  $ARGV[0]; 

$total = 0;
$total_gaps = 0;

open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

$seq = "";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>/ ) {
	process_seq ();
	$seq = "";
    } else  {
	s/\s//g;
	$seq .= $_;
    } 
}
process_seq ();
close FASTA;

printf "   %8.2f \n", $total_gaps/$total;

###########################################
sub process_seq () {   
    $total      += length $seq;
    $total_gaps += ( $seq =~ s/\-/a/g );    
}
