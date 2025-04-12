#!/usr/bin/perl -w

(@ARGV > 1) || 
    die "Usage: fasta_rename <input fasta>  <name file>  \n"; 

open (FASTA, "<", $ARGV[0]);
open (NAMES, "<", $ARGV[1]);

my %new_name = ();
while (<NAMES>) {
    chomp;
    my ($old, $new) = split;
    $new_name{$old} = $new;
}

while (<FASTA>) {
    if (/^>\s*(\S+)/) {
	if (defined $new_name{$1}) {
	    print ">$new_name{$1}\n";
	} else {
	    print;
	}
  } else {
      print;
  }
}

