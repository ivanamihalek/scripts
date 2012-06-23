#!/usr/bin/perl -w 
# shorten the names staring with gi (like in entres\z return)
(@ARGV == 2 ) ||
    die "Usage: $0 <names lis>  <fasta file> \n";


open  ( NAMES, "<$ARGV[0]" ) ||
    die "Cno $ARGV[0]: $!\n";


while ( <NAMES> ) {
    next if ( !/\S/);
    chomp;
    ($old, $new) = split " ";
    $new_name{$old} = $new;
}


open  ( FASTA, "<$ARGV[1]" ) ||
    die "Cno $ARGV[1]: $!\n";


while (<FASTA>) {
    if ( />s*(\w+)\s/ ) { # for pdb_seqres
	if ( defined $new_name {$1} ) {
	    print ">$new_name{$1}\n";
	} else {
	    print;
	}
    } else {
	print;
    }
 }


