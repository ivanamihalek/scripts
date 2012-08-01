#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0]  ) ||
    die "Usage: pdb_chain_rename.pl   <pdb_file>  [<new_chain_name>].\n";

$pdbfile = $ARGV[0];
if ( defined $ARGV[1] ) {
    $new_name = $ARGV[1] ;
} else {
    $new_name = "A";
}

$new_name =chr ( ord ($new_name) -1 )  ;

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";


$old_chain = "";   

while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print  ;
	next;
    }

    $line = $_;
    $chain = substr ( $line,  21, 1);
    if ( $chain ne $old_chain ) {
	 $new_name =chr ( ord ($new_name) + 1 )  ;
	 $old_chain = $chain;
    }
    substr ( $line,  21, 1) = $new_name;
    print $line;
}

close IF;
