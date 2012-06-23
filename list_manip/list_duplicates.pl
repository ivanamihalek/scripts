#! /usr/bin/perl -w

@ARGV || die "Usage: $0 <file> [<$column>]\n";

$column = 0;
(@ARGV==2) && ($column = $ARGV[1]-1);

open (IF, "<$ARGV[0]") || die "Cno $ARGV[0]: $!\n";

while ( <IF> ) {
    next if ( !/\S/);
    chomp;
    @aux = split;
    $name = $aux[$column];
    if (defined $found{$name} ) {
	$found{$name} +=1;
	#print "$name appears $found{$name} times.\n";
	#print "$name\n";
    } else {
	$found{$name} = 1;
    }

    
}

close IF;

foreach $name( keys %found ) {
    print "$name      $found{$name} \n";
}
