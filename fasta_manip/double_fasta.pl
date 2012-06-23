#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# double each sequence in fasta (beginning-to-end)


defined $ARGV[0]  ||
    die "Usage: double_fasta.pl  <fasta_file>.\n"; 

$fasta =  $ARGV[0]; 


open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {

	$name = $1;
	$sequence{$name} = "";
    } else  {
	s/\-/\./g;
	s/\#/\./g;
	s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}

close FASTA;


#double each sequence
foreach $name ( keys %sequence  ) {
    $sequence{$name} .= $sequence{$name};
}


foreach $seq_name ( keys %sequence ) {
	
    @seq = split ('', $sequence{$seq_name});
    print  "> $seq_name \n";
    $ctr = 0;
    for $i ( 0 .. $#seq ) {
	if ( $seq[$i] !~ '\.' ) {
	    print   $seq[$i];
	    $ctr++;
	    if ( ! ($ctr % 50 ) ) {
		print  "\n";
	    }
	    
	}
    }
    print  "\n";
}
