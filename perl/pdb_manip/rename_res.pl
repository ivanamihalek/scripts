#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( @ARGV > 2  ) ||
    die "Usage: $0   <pdb_file> <new res name>  ".
    "  [<orig res name>].\n";


($pdbfile, $new_name) = @ARGV;

$old_name = "";
if ( defined $ARGV[2] ) {
   $old_name =  $ARGV[2]; 
}

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";


    
while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print;
	next;
    }

    $res_name = substr $_,  17, 3; $res_name=~ s/\s//g;

    if ( $old_name && $res_name != $old_name) {
	print;
	next;
    }
    $line = $_;
    (substr $line, 17, 3) = $new_name;
    print $line;
    
}

close IF;
