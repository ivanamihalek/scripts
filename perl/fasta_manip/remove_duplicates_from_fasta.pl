#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: remove_duplicates_from_fasta.pl  <fasta_file>.\n"; 

$fasta =  $ARGV[0]; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

open (OF, ">duplicates")  or die "error opening duplicates file\n";

$reading = 0;
while ( <FASTA> ) {
    next if ( !/\S/);
    if (/^>/ ) {
	chomp;
	$name = $_;
	
	if ( defined $sequence{$name} ) {
	    print OF "duplicate name $name\n";
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
    if ( ! $printed) {
	print "$name\n";
	print $sequence{$name};
	push @printed, $sequence{$name};
    } else {
	#print OF $name, "\n";
	print  OF " duplicate sequence: $name} \n";
    }

}

close OF;
