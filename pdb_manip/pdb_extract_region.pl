#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(@ARGV  ) ||
    die "Usage: $0 <pdb_file> [<chain_name or \"-\"> <from> <to>].\n";


$pdbfile = shift @ARGV;
$query_chain_name = "";
$from = -10000;
$to   =  10000; 

if ( @ARGV ) {
    $query_chain_name = shift @ARGV;
}
if ( @ARGV ) {
    $from = shift @ARGV;
}
if ( @ARGV ) {
    $to   = shift @ARGV;
}


( $query_chain_name eq "-") && ( $query_chain_name = "");

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";


    
while ( <IF> ) {

    last if ( /^ENDMDL/);
    #last if ( /^TER/);
    next if ( ! /^ATOM/ && ! /^HETATM/ );
    $line = $_;

    if ( ! $query_chain_name || 
	 substr ( $line,  21, 1) eq $query_chain_name ) {
	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	( $from <= $res_seq && $res_seq <= $to )  &&
	    print $line;
    }
}

close IF;
