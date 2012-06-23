#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[1] ||
    die "Usage: extr_res__from_pdb.pl <res_list> <pdb_file>.\n"; 

$resfile = $ARGV[0];
$pdbfile = $ARGV[1];

open ( RES, "<$resfile" ) ||
    die "Cno $resfile: $! .\n";

@reslist = ();


while ( <RES> ) {
    next if ( /^%/ );
    next if ( !/\S/ );
    chomp;
    @aux = split;
    push @reslist, $aux[0];
}

close RES;


open ( PDB, "<$pdbfile" ) ||
    die "Cno $pdbfile: $! .\n";

while ( <> ) {
    next if ( ! (/^ATOM/ || /^HETATM/) ) ;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $res_seq =~  s/\s//g;
    for  $res ( @reslist) {
	if ( $res eq $res_seq ) {
	    print;
	}
    }
     
}



close PDB;
