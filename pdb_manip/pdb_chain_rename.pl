#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0]  ) ||
    die "Usage: $0   <pdb_file> ".
    "  [<old_chain_name> <new_chain_name> <res from> <res to>].\n";

$pdbfile = $ARGV[0];
if ( defined $ARGV[1] ) {
    $old_name = $ARGV[1];
} else {
    $old_name = "";
}
if ( defined $ARGV[2] ) {
    $new_name = $ARGV[2];
} else {
    $new_name = "A";
}
if ( defined $ARGV[3] ) {
    $from = $ARGV[3] ;
} else {
    $from = -100 ;
}
if ( defined $ARGV[4] ) {
    $to = $ARGV[4] ;
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
    $chain_name = substr ( $_,  21, 1);

    if ($old_name && $chain_name ne $old_name) {
	print;
	next;
    }
    
    if ( $res_seq < $from  ||  $res_seq > $to) {
	print;
	next;
    }

    $line = $_;
    substr ( $line,  21, 1) = $new_name;
    print $line;

}

close IF;
