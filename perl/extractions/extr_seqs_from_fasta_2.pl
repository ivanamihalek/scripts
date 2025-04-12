#! /usr/bin/perl -w
# same as extr_seqs_from_fasta.pl, only expetcs thename in the format >gi|287562976|<anything>....
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined $ARGV[0] &&  defined $ARGV[1] ||
    die "Usage: extr_seqs_from_fasta.pl <name_list> <fasta_file>.\n"; 

$list = $ARGV[0]; 
$fasta =  $ARGV[1]; 
open ( LIST, "<$list") ||
    die "Cno $list: $!\n";


while ( <LIST>) {
    if ( /\w/ ) {
	chomp;
	s/\s//g; # get rid of the whitespace
	$needed{$_} = 1; 
    }
}
close LIST;


open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {

    if (/^>/ ) {
	/^>\s*gi\|(\d+)\|/;
	$gi = $1;
    }
    if ( defined $needed{$gi}) {
	print;
    }
}

close FASTA;
