#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( defined $ARGV[2] ) || die "Usage: find_distance_to_cat_site.pl <pdb> <substratefootprint> <partner pdb>.\n";

($pdb, $foot, $partner) = @ARGV;

$ext = "";
($pdbname, $ext) = split '\.', $pdb; 
$chain = 0;

# try to guess from the name if the chain is involved:
( length $pdbname == 5 ) && ($chain = 1);

$cat = "";
open (IF, "<$foot") || die "Cno $foot: $!.\n";
while ( <IF> ) {
    next if ( /^\#/ );
    @aux = split;
    if ( $chain ) {
	$cat .=  `awk \'\$6 == $aux[0]\' $pdb`;
    } else {
	$cat .=  `awk \'\$5 == $aux[0]\' $pdb`;
    }
}
close IF;

open (OF, ">foot.pdb") || die "Cno foot.pdb: $!.\n";
print OF $cat;
close OF;

$cmd = "/home/i/imihalek/c-utils/geom_epitope foot.pdb $partner 100 | awk \'\$2 != \"id\" {print \$5}\' | sort -g |head -n1";
print `$cmd`;
