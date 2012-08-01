#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0] ) ||
    die "Usage: remove_alt_loc.pl <pdb_name>.\n";
$pdb = $ARGV[0];

open ( IF, "<$pdb" ) ||
    die "Cno $pdb:$!.\n";

while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print ;
	next;
    }

    $alt_loc = substr $_,16, 1 ;
    next if ( $alt_loc ne  " " && $alt_loc ne "A" );

    print ;
}


close IF;


