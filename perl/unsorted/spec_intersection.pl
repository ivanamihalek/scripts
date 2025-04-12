#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);


(defined   $ARGV[0]) && (defined   $ARGV[1]) ||
    die "Usage: spec_intersection.pl <list1> <list2>.\n"; 

$file1 =  $ARGV[0];
$file2 =  $ARGV[1];

open ( F1, "<$file1" )
    || die "Cno $file1: $! \n";

open ( F2, "<$file2" )
    || die "Cno $file2: $! \n";

%orgs1 = ();
while ( <F1> ) {
    chomp;
    @aux = split;
    $name = lc join (' ', @aux[1 .. $#aux]);
    if ( ! defined $orgs1{$name} ) {
	$orgs1{$name} = 1;
    }
    
}
%orgs2 = ();
while ( <F2> ) {
    chomp;
    @aux = split;
    $name = lc join (' ', @aux[1 .. $#aux]);
    if ( ! defined $orgs2{$name} ) {
	$orgs2{$name} = 1;
    }
    
}


for $name ( keys %orgs1 ) {
    if ( defined $orgs2{$name} ) {
	print "$name \n";
    }
}
