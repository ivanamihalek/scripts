#! /usr/gnu/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[1] ) ||
    die "Usage: pdbcleanup.pl <pdb_name>  <chain_id>.\n";
$pdb = $ARGV[0];
$current_chain_id =  $ARGV[1];
open ( IF, "<$pdb" ) ||
    die "Cno $pdb:$!.\n";
open ( OF, ">$pdb.clean" ) ||
    die "Cno $pdb.clean:$!.\n";


$res_ctr = 0;
$old_res_seq = -1; 
$prev_res_seq = -1;

while ( <IF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print OF ;
	next;
    }

    # looks like I have to format it seriously
    $record = substr $_, 0, 6;  $record =~ s/\s//g;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $name = substr $_,  12, 4 ;  $name =~ s/\s//g; 
    #$name =~ s/R//;$name =~ s/P//;$name =~ s/A//;
    $name =~ s/\*//g; 
    
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
    $chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;

    next if ( $alt_loc =~ "B" );
    $alt_loc = " ";
    if ( $res_seq != $old_res_seq ) {
	$old_res_seq =  $res_seq;
	$res_ctr++;
    }
    if ( $res_seq < $prev_res_seq ) {
	$current_chain_id = chr ( ord ($current_chain_id ) + 1);
    }
    $prev_res_seq = $res_seq;
    #if (!$chain_id ||  $chain_id =~ /\s/ ) {
	$chain_id = $current_chain_id;
    #}

    printf OF "%-6s%5d  %-3s%1s%-3s %1s%4d%1s   %8.3f%8.3f%8.3f", 
    $record,   $serial,  $name,   $alt_loc,   $res_name,
    $chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;

    print  OF "\n";
}


close IF;
close OF;


