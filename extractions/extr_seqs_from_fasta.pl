#! /usr/bin/perl -w
use Getopt::Std;
use IO::Handle;         #autoflush
# FH -> autoflush(1);
defined $ARGV[0] &&  defined $ARGV[1] ||
    die "Usage: extr_seqs_from_fasta.pl <name or name_list> <fasta_file> [-n].\n"; 
$opt_n = 0;
getopts('n');

$list  = $ARGV[0]; 
$fasta = $ARGV[1]; 

if ( ! -e $list ) { #its not a file, it's a single name
    $selected{$list} = 1;
} else {
    open ( LIST, "<$list") || die "Cno $list: $!\n";
    while ( <LIST>) {
	if ( /\w/ ) {
	    @aux = split;
	    $selected{$aux[0]} = 1; 
	}
    }
    close LIST;
}


open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";
$name = "";

TOP: while ( <FASTA> ) {

    if (/^>\s*(.+?)\s/ ) {
	$seen{$name} = 1; 
	$name = $1;
	$name =~ s/\s//g; # get rid of the whitespace
	$found{$name} = 1;
    }
    if ( !$opt_n && defined $selected{$name} && ! defined $seen{$name} ) {
	print;
    } elsif ($opt_n && ! defined $selected{$name} && ! defined $seen{$name}) {
	print;
    }
}

close FASTA;

foreach $name ( keys %selected ) {
    if ( ! defined $found{$name} ) {
	die  "$name not found in $fasta\n";
    }
}
