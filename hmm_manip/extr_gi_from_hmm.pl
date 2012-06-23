#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    last if ( /Alignments of top-scoring domains/ );
    next if ( !/^gi\|/ ) ;
    chomp;
    @aux = split  '\|' ;
    $name = $aux[1];
    next if (defined $found{$name} );
    $found{$name} = 1;
    print "$name\n";
}
