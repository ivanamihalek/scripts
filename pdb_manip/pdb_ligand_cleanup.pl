#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( @ARGV   ) ||
    die "Usage: $0   <pdb_file>   <new res name>   [<res number>].\n";


($pdbfile, $new_name) = @ARGV;

$new_res_seq = sprintf "%4d", 1;
if ( defined $ARGV[2] ) {
   $new_res_seq =  sprintf "%4d",$ARGV[2]; 
}

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";


    
while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print;
	next;
    }


    $line = $_;
    (substr $line, 17, 3) = $new_name;
    (substr $line, 22, 4) = $new_res_seq;
    (substr $line, 0, 6)  = "ATOM ";
    print $line;
    
}

close IF;
