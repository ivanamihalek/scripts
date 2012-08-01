#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
# of the alternative location 

while ( <> ) {
    @aux = split '';
    if ( $aux[16] !~ "B") {
	print;
    }
}
