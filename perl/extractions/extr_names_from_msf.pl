#! /usr/bin/perl -w

while ( <> ) {
    if ( /Name/ ) {
	chomp;
	@aux = split;
	# next if ($aux[1] =~  /\D/ );
	print "$aux[1]\n";
    }
    
}
