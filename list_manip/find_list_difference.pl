#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[1] ) ||
    die "Usage [to subtract list2 from list1]: find_list_difference.pl <list1> <list2>.\n";

$list1 = $ARGV[0];
$list2 = $ARGV[1];

open (IF, "<$list2" ) || die "CNO $list2: $!.\n";

while ( <IF> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    if ( defined $found{$aux[0]} ) {
    } else {
	$found{$aux[0]} = 1;
    }
}

close IF;

open (IF, "<$list1" ) || die "CNO $list1: $!.\n";
while ( <IF> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    if ( defined $found{$aux[0]} ) {
    } else {
	print $_, "\n";
    }
}
close IF;

