#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    if ( /^ATOM/) {
	print substr $_, 0, 55;
	print "\n";
    } else {
	print;
    }
   
}
