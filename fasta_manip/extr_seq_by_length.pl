#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[2]  ||
    die "Usage: extr_seq_by_length.pl      <fasta_file>  <shortest>  <longest>.\n"; 

$fasta =  $ARGV[0]; 
$from =  $ARGV[1]; 
$to  =  $ARGV[2]; 

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
    next if ( $len < $from || $len > $to );
    @seq = split ('', $sequence{$name});
    print  ">$name \n";
    $ctr = 0;
    for $i ( 0 .. $#seq ) {
	if ( $seq[$i] !~ '\.' ) {
	    ( $seq[$i] =~ '\-' ) && ( $seq[$i] = '.' );
	    print  $seq[$i];
	    $ctr++;
	    if ( ! ($ctr % 50) ) {
		print  "\n";
	    }
	    
	}
    }
    print "\n";
}
