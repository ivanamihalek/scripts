#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0]  ) ||
    die "Usage: split_into_chains.pl   <pdb_file>.\n";

$pdbfile = $ARGV[0];

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

@aux = split "/", $pdbfile;
$pdbroot = pop @aux;
$pdbroot =~ s/\.pdb//;


$old_chain_name = "";
    
while ( <IF> ) {

    last if ( /^ENDMDL/);
    next if ( ! /^ATOM/  );
    $line = $_;
    $chain_name = substr ( $line,  21, 1) ;
    if ( $chain_name ne $old_chain_name ) {
	( $chain_name ) && close OF;
	if ( $chain_name =~ /\s/ ) {
	    $filename = "$pdbroot\_.pdb";
	} else {
	    $filename = "$pdbroot$chain_name.pdb";
	}
	open ( OF, ">$filename" ) ||
	    die "Cno $filename: $!\n";
	$old_chain_name = $chain_name;
    }
    print OF $line;
}

( $chain_name ) && close OF;

close IF;

