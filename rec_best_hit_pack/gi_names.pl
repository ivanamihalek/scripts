#!/usr/bin/perl -w 
# shorten the names staring with gi (like in entrez return)


while (<STDIN>) {
    if ( />/ ) { # for gi names
	/>\s*gi\|(\d*)\|.*\[(.*)\]/;
	(defined $1 && defined $2 ) || 
	    die "Improper gi header: $_\n";
	$gi = $1;
	@aux = split " ", uc $2;
	$aux[0] = substr $aux[0], 0, 3;
	$aux[1] = substr $aux[1], 0, 3;
	$name = join "_", @aux[0..1];
	print ">$gi\_$name\n";
    } else {
	print;
    }
}


