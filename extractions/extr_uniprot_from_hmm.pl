#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    last if ( /Scores for complete sequences/ );
}
<>;
<>;

while ( <> ) {
    last if ( /Parsed for domains/ );
    next if ( !/\S/ ) ;
    chomp;
    /.+\((\w+?)\).+/;
    $name = $1;
    next if ( $name =~ /fragment/i);
    next if (defined $found{$name} );
    $found{$name} = 1;
    print "$name\n";
}
