#! /usr/bin/perl -w

defined $ARGV[0]  ||
    die "Usage: fasta2msf.pl  <fasta_file>.\n"; 

sub process(@);

$fasta =  $ARGV[0]; 

%count = ();
$total = 0;

open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

$ctr = 0;
$sequence = "";
$reading = 0;
TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {
	#(  $ctr % 1000 ) || printf  " %10d \n",   $ctr;
	$reading  && process ($sequence);
	#if ( $ctr % 100 ) {
	#    $reading = 0;
	#} else {
	    $reading = 1;
	#}
	$sequence = "";
	$ctr ++;
    } else  {
	next if ( ! $reading );
	s/\-/\./g;
	s/\#/\./g;
	$sequence .= $_;
    } 
}
close FASTA;

#printf  " %10d \n",   $ctr;

$ctr = 0;

foreach $trigram ( keys %count) {
    $ctr ++;
    printf  " %8.3e  %3s  %4d \n", $count{$trigram}/$total, $trigram, $ctr;
}




sub process (@) {
    my $sequence = $_[0];
    my $offset;
    my $trigram;

    for $offset ( 0 .. length($sequence)-3 ) {
	$trigram = substr $sequence, $offset, 3;
	next if ( $trigram =~ /\./ );
	$trigram = uc $trigram;
	next if ( $trigram =~ /[BZX\.]/ );
	if ( defined $count{$trigram} ) {
	    $count{$trigram} ++;
	} else {
	    $count{$trigram} = 1;
	}
	$total ++;
    }
    
}

