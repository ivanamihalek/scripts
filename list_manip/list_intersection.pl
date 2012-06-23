#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
( defined $ARGV[1] ) ||
    die "Usage: list_intersection.pl <column> <list1> <list2> ...\n";

$column = shift @ARGV;
$column--;
@list_names = @ARGV;

$no_of_lists = @list_names;

@list = ();
undef $/;
foreach $list_name ( @list_names ) {
    open ( IF,  "<$list_name") || die "Cno $list_name:$!.\n";
    $_ = <IF>;
    push @list, split '\n';
    close IF
}
$/ = "\n";


foreach $element ( @list ) {
    @aux = split ' ', $element;
    if ( ! defined $count{$aux[$column]} ) {
	$count{$aux[$column]} = 1;
    } else {
 	$count{$aux[$column]} ++;
   }
}


foreach $name ( keys %count ) {
    if ( $count{$name} == $no_of_lists ) {
	print $name, "\n";
    }
}
