#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
(@ARGV > 2  && !($#ARGV%2)  )  ||
    die "Usage: extr_region_from_pdb.pl <pdb_file> [-c <chain>]  <count from>  <count to> ".
" [<count from> <count to> ...].\n"; 

$pdbfile  = shift  @ARGV;
$chain    = "";

if ( $ARGV[0] eq "-c" ) {
    shift  @ARGV;
    $chain = shift  @ARGV;
}
@from_to  =  @ARGV;
%seen = ();
open ( PDB, "<$pdbfile" ) ||
    die "Cno $pdbfile: $! .\n";

while ( <PDB> ) {
    last if ( /^ENDMDL/);
    next if ( ! (/^ATOM/ || /^HETATM/) ) ;
    

    $chain_id = substr $_, 21, 1;
    next if ( $chain && ($chain ne $chain_id) );

    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;

    for ( $ctr=0; $ctr < $#from_to; $ctr+=2 ) {
	if ( $from_to[$ctr] <= $res_seq  && 
	     $res_seq <= $from_to[$ctr+1] ) {
	    #try to handle insertion code cases:
	    $atom_name = substr $_, 12, 4; $atom_name=~ s/\s//g;
	    if ( ! defined $seen{"$res_seq $atom_name" } ){
		$seen{"$res_seq $atom_name"} = 1;
		print $_;
	    }
	    last;
	}
    }
     
}

close PDB;
