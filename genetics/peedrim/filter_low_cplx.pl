#! /usr/bin/perl -w


sub process (@);

defined $ARGV[0]  ||
    die "Usage: $0  <fasta_file>.\n"; 

$fasta =  $ARGV[0]; 


open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

$sequence = "";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {
	$sequence && process ($name,$sequence); 
	$name = $1;
	$name =~ s/\s//g;
	$sequence = "";
    } else  {
	s/\-/\./g;
	s/\#/\./g;
	s/\s//g;
	#s/x/\./gi;
	$sequence .= lc $_;
    } 
}
close FASTA;

###############################

sub process ( @ ) {

    my ($name,$sequence) = @_;
    my %frac = ();
    my $len = length $sequence;
    my $low_fractions;
    my $orig_seq = $sequence;

    (length $orig_seq < 18) && return;

    $low_fractions = 0;
    foreach $nt ( "a", "c", "t", "g") {
	$frac{$nt} = ($sequence =~ s/$nt//g);
	($frac{$nt}/$len < 0.05 ) &&  $low_fractions++;
    }
    if ( $low_fractions == 0 ) {
	#print " $orig_seq \n";
	#foreach $nt ( "a", "c", "t", "g") {
	#    printf "\t %s  %2d  %4.2f \n",  $nt,  $frac{$nt}, $frac{$nt}/$len;
	#}
	print ">$name\n";
	print "$orig_seq\n";
    }
    
}





