#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    next if ( !(/\w/) );
    @aux = split '\|';
    print "$aux[1] \n";
}
