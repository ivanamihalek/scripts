#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
(@ARGV) || 
    die "Usage: $0 <file name> [<column>]\n";
$file = $ARGV[0];
if (@ARGV > 1) {
    $column = $ARGV[1]-1;
} else {
    $column = 0;
}


open (IF, "<$file") ||
    die "Cno $file: $!.\n";

while ( <IF> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    if ( defined $found{$aux[$column]} ) {
    } else {
	$found{$aux[$column]} = 1;
	print "$_\n";
    }
}

close IF;
