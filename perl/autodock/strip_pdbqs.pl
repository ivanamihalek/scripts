#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    if  (/^ATOM/ || /^HETATM/ ) {
	chomp;
	print  substr ( $_, 0, 66), "\n";
    } else {
	print;
    }

}
