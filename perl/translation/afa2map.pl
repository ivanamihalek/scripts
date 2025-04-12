#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: afa2msf.pl  <afa_file>.\n"; 

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
	s/\s//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close FASTA;

( @names  == 2 ) 
    || die "afa2map.pl expects exactly 2 sequences\n";

for ($seq_ctr=0; $seq_ctr <2; $seq_ctr++ ) {
    $seq[$seq_ctr] = ();
    @{$seq[$seq_ctr]} = split "", $sequence{$names[$seq_ctr]};
}

$length = length $sequence{$name};

for ($seq_ctr=0; $seq_ctr <2; $seq_ctr++ ) {
    $counter[$seq_ctr] = 0;
    printf " %s ",  $names[$seq_ctr];
}
print "\n";

for ( $ctr=0; $ctr < $length; $ctr ++ ) {
    for ($seq_ctr=0; $seq_ctr <2; $seq_ctr++ ) {
	if ( $seq[$seq_ctr][$ctr] eq "." ) {
	    printf " %4s  %2s ", ".", ".";
	} else {
	    $counter[$seq_ctr]++;
	    printf " %4d  %2s ", $counter[$seq_ctr], $seq[$seq_ctr][$ctr];
	}
    }
    print "\n";
}


