#!/usr/bin/perl -w 
# shorten the names staring with gi (like in entres\z return)


while (<STDIN>) {
    next if ( !/\S/);
    if (0) {
    } elsif ( />\w*\:([\w\.]+)\s*/ ) { # yeast genomes
	print ">$1\n";
    } elsif ( />.*\|.*\|(\w+?)\s/ ) { # for second name in uniprot
	print ">$1\n";
    } elsif ( />.*ortholog.*\|\s*(\w+)\s*\|/ ) { # for omar
	print ">$1\n";
    } elsif ( />(\w+)\s/ ) { # for pdb_seqres
	print ">$1\n";
    } elsif ( />lcl\|(\w+)\s/ ) { # for fastacmd
	print ">$1\n";
    } elsif ( />\s*gi\|(\d+)\|/ ) { # for gi names
	$name = $1;
	if ( /\[(.+)\]/) {
	    $sci_name = $1;
	    $sci_name =~ s/\(.*\)//g;
	    @aux = split " ", $sci_name;
	    @short = map {substr $_, 0, 3}  @aux;
	    $spec = uc join "_",  @short[0..1];
	    $name = $spec."_".$name;
	}
	print ">$name\n";
    } elsif ( />.*\|(\w+?)\s/ ) { # for uniprot names
	print "> $1\n";
    } elsif ( /([\w\d]+?)\// ) { # for Sebastian
	print ">$1\n";
    } elsif ( /^>.*\|sp\|([\w\d]+?)\|/ ) { # for swissprot names
	print ">$1\n";
    } elsif ( />\s*lcl\|(\w+)\s/ ) { # for lcl names
	print ">$1\n";
    } elsif ( />\s*tr\|(\w+?)\|/ ) { # for trembl  names
	print ">$1\n";
     } elsif ( />([\w\d]+?)\s/ ) { # for PDB names
	print ">$1\n";
    } elsif ( />\s*\w+\|\w+[\|\s](\w+)[\|\s]/ ) {
	print ">$1\n";
    } elsif ( />\s*\w+\|\w+[\|\s]\((\w+)\)[\|\s]/ ) {
	print ">$1\n";
    } elsif ( />\s*(\w+)\s*\[/ ) {
	print ">$1\n";
    } else {
	print;
    }
 }


