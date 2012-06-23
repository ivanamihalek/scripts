#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    if ( /^ATOM/ || /^HETATM/ ) {
	(substr $_, 12, 1) =  " ";
	(substr $_, 14, 2) =  "  ";
    } 
    print;
}



