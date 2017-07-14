#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0] ) ||
    die "Usage: pdb_renumber.pl <pdb_name> [<offset> <chain>  <start_from_residue>].\n";
$pdb = $ARGV[0];

open ( IF, "<$pdb" ) ||
    die "Cno $pdb:$!.\n";

if ( defined $ARGV[1] ) {
    $offset = $ARGV[1];
} else { 
    $offset = 0;
}

$chain = "";
if ( defined $ARGV[2] &&  $ARGV[2] ne "-" ) {
    $chain = $ARGV[2];
}
$start_from_residue = -1000;
if  ( defined $ARGV[3] ) {
    $start_from_residue  = $ARGV[3]
}

$old_res_seq = -200;
$old_res_name = "";
$old_chain_id = "blah";
while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print;
	next;
    }

    # looks like I have to format it seriously
    $record = substr $_,  0, 6;  $record =~ s/\s//g;
    $serial = substr $_,  6, 5;  $serial =~ s/\s//g;
    $name   = substr $_, 12, 4 ; $name =~ s/\s//g; 
    #$name =~ s/R//;$name =~ s/P//;$name =~ s/A//;
    $name =~ s/\*//g; 
    
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
    $chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
    if ( $chain && $chain_id ne $chain) {
	print;
	next;
    }
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
    $x = substr $_, 30, 8;  $x=~ s/\s//g;
    $y = substr $_, 38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8;  $z=~ s/\s//g;

    if ( $chain_id ne $old_chain_id ) {
	$old_chain_id = $chain_id;
    }
    if ( $res_seq != $old_res_seq ||  ! ($res_name eq $old_res_name) ) {
	$old_res_seq  = $res_seq;
	$old_res_name = $res_name;
    }
    if ( $res_seq>=$start_from_residue) {
	$aux = sprintf "%4d", $res_seq+$offset;
	(substr $_, 22, 4) = $aux;
    }
    print;
    
}


close IF;


