#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: $0  <fasta_file>.\n"; 

$fasta =  $ARGV[0]; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {

	$name = $1;
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



foreach $name ( @names ) {
    print "$name ", length 	$sequence{$name}, "\n";
}
