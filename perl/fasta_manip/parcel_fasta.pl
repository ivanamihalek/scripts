#!/usr/bin/perl -w 
# shorten the names staring with gi (like in entres\z return)

$name = "";
 $seq = "";
while (<STDIN>) {
    if ( /^>/  ) { 
	if ( $name ) {
	    open ( OF, ">$name.seq") || die "Cno $name.seq: $!.\n";
	    print OF "> $name\n";
	    print OF  $seq;
	    close OF;
	    $seq = "";
	}
	if ( />\s*gi\|(\d+)\|/ ) { # for gi names
	    $name = $1;
	} elsif ( />\s*\w+\|\w+[\|\s](\w+)[\|\s]/ ) {
	    $name = $1;
	} elsif ( />\s*\w+\|\w+[\|\s]\((\w+)\)[\|\s]/ ) {
	    $name = $1;
	} 
	print $name, "\n";

    }else {
	$seq .= $_;
    }
}

