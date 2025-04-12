#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    last if ( /^  \#  RESIDUE AA STRUCTURE/ );
}


while ( <> ) {
    #$num = substr $_, 0 , 5;
    $res = substr $_, 5 , 5;
    $acc = substr $_,35, 3;
    print "$res\t$acc\n";
    
}
