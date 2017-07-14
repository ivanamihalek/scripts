#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: fasta2msf.pl  <fasta_name>.\n"; 

$fasta =  "$ARGV[0].fasta"; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {

	$name = $1;
	@aux = split '\|', $name;
	$name = $aux[1];
	push @names,$name;
	$sequence{$name} = "";
    } else  {
	s/\-/\./g;
	s/\#/\./g;
	s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close FASTA;


$fasta =  "$ARGV[0].new.fasta"; 

open ( FASTA, ">$fasta" ) ||
    die "Cno :$fasta  $!\n";
	

    foreach $seq_name ( @names ) {
	
	@seq = split ('', $sequence{$seq_name});
	print FASTA ">$seq_name \n";
	$ctr = 0;
	for $i ( 0 .. $#seq ) {
	    print FASTA  $seq[$i];
	    $ctr++;
	    if ( ! ($ctr % 100) ) {
		print FASTA "\n";
	    }

	}
	print FASTA "\n";
    }

close FASTA;
 

