#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
# assumes sse as a fasta list of seqs containing S, H, C or X annotation
# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: fasta2msf.pl  <fasta_file>.\n"; 

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
    $len = length 	$sequence{$name};
    print "$name  $len" ;
    $s_count = ( $sequence{$name} =~ tr/S//);
    $h_count = ( $sequence{$name} =~ tr/H//);
    $c_count = ( $sequence{$name} =~ tr/C//);
    $x_count = ( $sequence{$name} =~ tr/X//);
    
    printf "  S:%3d   H:%3d  C:%3d  X:%3d  \n",
    int ( 100*$s_count/$len),
    int ( 100*$h_count/$len),
    int ( 100*$c_count/$len),
    int ( 100*$x_count/$len);

}
