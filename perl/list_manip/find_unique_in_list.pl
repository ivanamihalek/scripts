#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    if ( defined $found{$aux[0]} ) {
	$found{$aux[0]} ++;
    } else {
	$found{$aux[0]} = 1;
    }
}

foreach $name ( keys %found ) {
    if ( $found{$name} == 1) {
	print "$name\n";
    }
}
