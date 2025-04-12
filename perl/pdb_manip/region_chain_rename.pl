#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0]  ) ||
    die "Usage: pdb_chain_rename.pl   <pdb_file>  <old chain name> <from> <to> <new name>.\n";

($pdbfile, $old_name, $from, $to, $new_name) = @ARGV;



open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$ignore_chain_name = 0;
if ( $old_name eq "-" ) {
    $ignore_chain_name = 1;
}


while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print  ;
	next;
    }

    $line = $_;
    $chain_id = substr $line, 21, 1;
    if ( $ignore_chain_name || ($chain_id eq  $old_name) ) {
	$residue = substr ( $line,  22, 4);
	if ( $residue >= $from && $residue <= $to ) {
	    substr ( $line,  21, 1) = $new_name;
	}
    }
    print $line;
}

close IF;
