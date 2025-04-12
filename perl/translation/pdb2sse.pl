#! /usr/bin/perl -w

(@ARGV > 1 ) ||
    die "Usage: $0 <full pdb entry> <chain>\n";

($pdb, $chain) = @ARGV;

open (PDB, "<$pdb") || die "CNo $pdb: $!.\n";
$pdb =~ /(\d.{3}?)\.pdb/;
defined $1 || 
    die "Nonstandard name: $pdb. (Full pdb entry?)\n";
$pdb_name = $1;


$old_res_seq  = -50;
$seq = "";
while ( <PDB> ) {
    if ( /^HELIX/ ) {
	$chain_id = substr $_, 19, 1;
	if ( $chain_id eq $chain ) {
	    $res_from =  substr $_, 21, 4; $res_from =~ s/\s//g;
	    $res_to   =  substr $_, 33, 4; $res_to =~ s/\s//g;
	    #print;
	    #print " $res_from  $res_to \n"; 
	    for $res_seq ($res_from .. $res_to) {
		$is_helix{$res_seq } = 1;
	    }
	}
    } elsif ( /^SHEET/ ) {
	$chain_id = substr $_, 21, 1;
	if ( $chain_id eq $chain ) {
	    $res_from =  substr $_, 22, 4; $res_from =~ s/\s//g;
	    $res_to   =  substr $_, 33, 4; $res_to =~ s/\s//g;
	    #print;
	    #print " $res_from  $res_to \n"; 
	    for $res_seq ($res_from .. $res_to) {
		$is_strand{$res_seq } = 1;
	    }
	}
    } elsif ( /^ATOM/ ) {
	$chain_id = substr ( $_,  21, 1);
	next if ( $chain_id ne $chain );
	$res_seq  = substr $_, 22, 5;  $res_seq=~ s/\s//g;
	$res_name = substr $_,  17, 4; $res_name=~ s/\s//g;
	if ( $res_seq ne $old_res_seq ) {
	    #print;
	    if ( defined $is_helix {$res_seq} ) {
		#print " $res_seq $res_name  H\n";
		$seq .= "H";
	    } elsif ( defined $is_strand {$res_seq}) {
		#print " $res_seq $res_name  S\n";
		$seq .= "S";
	    } else {
		#print " $res_seq $res_name  C\n";
		$seq .= "C";
	    }
	} 
	$old_res_seq = $res_seq;
    } elsif ( /^ENDMDL/) {
	last;
    }
}

$max = length $seq;
print ">$pdb_name$chain\n";
$ctr = 0;
do {
    print substr $seq, $ctr, 100;
    print "\n";
    $ctr += 100;
} while ($ctr <= $max );

