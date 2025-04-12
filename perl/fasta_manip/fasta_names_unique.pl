#!/usr/bin/perl -w 
# shorten the names staring with gi (like in entres\z return)

open (OUTF, ">name_resolution.txt");
%names_seen = ();
while (<STDIN>) {
    next if ( !/\S/);
    if (/>(\w+)\s/ ) { # for pdb_seqres
	$orig_name = $1;
	$name = lc $orig_name;
	$name =~ s/_//g; #the idiotic application called makeblastdb does not respect case, but tried to parse this as PDB
	if (defined $names_seen{$name}) {
	    $names_seen{$name} += 1;
	    $name .= "_".$names_seen{$name};
	} else {
	    $names_seen{$name} = 1;
	}
	print OUTF  "$orig_name  $name\n";
	print ">$name\n";
    } else {
	print;
    }
 }

close OUTF;
