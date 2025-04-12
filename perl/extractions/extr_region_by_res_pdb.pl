#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
(@ARGV > 2)  ||
    die "Usage: extr_region_by_res_pdb.pl <pdb_file> <res from> <res to>.\n"; 

($pdbfile, $count_from, $count_to) = @ARGV;



open ( PDB, "<$pdbfile" ) ||
    die "Cno $pdbfile: $! .\n";

$old_res_seq = -100;

while ( <PDB> ) {
    next if ( ! (/^ATOM/ || /^HETATM/) ) ;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;

    last if ( $res_seq  > $count_to);

    if ( $res_seq  >= $count_from) {
	print;
    }
     
}



close PDB;
