#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[1]  ) ||
    die "Usage: pdb_chain_rename.pl   <pdb_file>  <ligand_name>.\n";

$pdbfile = $ARGV[0];
$pdbdir = "/home/pine/pdbfiles/";
( -e $pdbfile ) || ( $pdbfile = $pdbdir.$pdbfile);
open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$ligand = $ARGV[1];

$resno = "";
(defined  $ARGV[2] ) && ( $resno =  $ARGV[2] );
    
while ( <IF> ) {

    next if ( ! /^HETATM/ );
   
    next if (  substr ( $_,  17, 3)  ne   $ligand);
    if (  $resno ) {
	$aux = substr ( $_,  22, 5);
	$aux =~ s/\s//g;
	next if ( $aux ne $resno);
    }
    print;

}

close IF;
