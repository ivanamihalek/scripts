#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    if ( /^ATOM/) {
	$line = $_;
	(substr $line, 60, 6) = "  0.00";
	print "$line";
    } else {
	print;
    }
   
}
