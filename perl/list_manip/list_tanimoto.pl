#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[1] ) ||
    die "Usage: list_tanimoto.pl <list1> <list2>.\n";

$list1 = $ARGV[0];
$list2 = $ARGV[1];
$list_size_1 = $list_size_2 = 0;
$intersection_size = 0; 

open (IF, "<$list2" ) || die "CnO $list2: $!.\n";

while ( <IF> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    if ( defined $found_1{$aux[0]} ) {
    } else {
	$found_1{$aux[0]} = 1;
	$list_size_1 ++;
    }
}

close IF;

open (IF, "<$list1" ) || die "CnO $list1: $!.\n";
while ( <IF> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    if ( defined $found_2{$aux[0]} ) {
    } else {
	$found_2{$aux[0]} = 1;
	$list_size_2 ++;
	if ( defined $found_1{$aux[0]} ) {
	    $intersection_size ++;
	}
    }
}
close IF;

$tanimoto =  $intersection_size* $intersection_size/($list_size_1 *$list_size_2);

printf " %5d  %5d  %5d  %8.3f   %8.3f \n",  
    $list_size_1,   $list_size_2 , $intersection_size,  $intersection_size/$list_size_1,   $tanimoto;
