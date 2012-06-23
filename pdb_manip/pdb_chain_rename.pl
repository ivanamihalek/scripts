#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0]  ) ||
    die "Usage: $0   <pdb_file> ".
    "  [<new_chain_name> <res from> <res to>].\n";

$pdbfile = $ARGV[0];
if ( defined $ARGV[1] ) {
    $new_name = $ARGV[1];
} else {
    $new_name = " ";
}
if ( defined $ARGV[2] ) {
    $from = $ARGV[2] ;
} else {
    $from = -100 ;
}
if ( defined $ARGV[3] ) {
    $to = $ARGV[3] ;
} else {
    $to = 10000 ;
}

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";


    
while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print  ;
	next;
    }

    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    if ( $from <= $res_seq && $res_seq <= $to ) {
	$line = $_;
	substr ( $line,  21, 1) = $new_name;
	print $line;
    } else {
	print;
    }
}

close IF;
