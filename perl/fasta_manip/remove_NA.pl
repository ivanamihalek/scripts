#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: remove_NA.pl  <fasta_file>.\n"; 

$fasta =  $ARGV[0]; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";


$reading = 0;
while ( <FASTA> ) {
    next if ( !/\S/);
    if (/^>(.+)/ ) {
	chomp;
	$name = $1;
	if ( defined $sequence{$name} ) {
	    $reading = 0;
	} else {
	    $reading = 1;
	    push @names,$name;
	    $sequence{$name} = "";
	    
	}
    } elsif ( $reading)  {
	$sequence{$name} .= $_;
    } 
}
close FASTA;

@printed = ();
foreach $name (@names) {
    $printed = 0;
    foreach $seq (@printed ) {
	if ( $sequence{$name} eq $seq ) {
	    $printed = 1;
	    last;
	}
    }
    next if ( $printed);
    next if ( $sequence{$name} =~ /U/ );
    next if ( $sequence{$name} !~ /[VLIMSEDRKHPFYWQN]/ );
    
    print ">$name\n";
    print $sequence{$name};
    
}
# 12345678901234567890
# GAVLICMSTEDRKHPFYWQN
# VLIMSEDRKHPFYWQN
