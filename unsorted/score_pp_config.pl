#! /usr/gnu/bin/perl -w


$CUTOFF_DIST = 5; 

(defined $ARGV[0] && defined $ARGV[1]  ) ||
    die "usage: cont_mat.pl  <pdb_name_1> <pdb_name_2> \n.";

$pdb1 =  $ARGV[0];
$pdb2 =  $ARGV[1];

$pdbfile1 = $ARGV[0]."/".$ARGV[0].".pdb";
$pdbfile2 = $ARGV[1]."/".$ARGV[1].".pdb";

$ranksfile1  = $ARGV[0]."/pruned.ranks";
$ranksfile2  = $ARGV[1]."/pruned.ranks"; 
$res_column  = 1;
$rank_column = 6;


open (PDBFILE1, "<$pdbfile1") ||
    die "could not open $pdbfile1.\n";

open (PDBFILE2, "<$pdbfile2") ||
    die "could not open $pdbfile2.\n";

@chain1 = ();
$prev_aa = 0; $ctr = 0;
while ( <PDBFILE1> ) {
    next if ( ! /^ATOM/ );
    chomp;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;

    if (  $res_seq != $prev_aa ) {
	
	push @chain1, $res_seq;
	if ( $prev_aa  ) {
	    $atom_1_ctr{$prev_aa} = $ctr;
	}
	$ctr = 0;
	$prev_aa = $res_seq;
    }
    $atom_1 {$res_seq}[$ctr][0] = $serial;
    $atom_1 {$res_seq}[$ctr][1] = $x;
    $atom_1 {$res_seq}[$ctr][2] = $y;
    $atom_1 {$res_seq}[$ctr][3] = $z;
    $ctr++;
}

$atom_1_ctr{$prev_aa} = $ctr;


@chain2 = ();
$prev_aa = 0; $ctr = 0;
while ( <PDBFILE2> ) {
    next if ( ! /^ATOM/ );
    chomp;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;

    if (  $res_seq != $prev_aa ) {
	
	push @chain2, $res_seq;
	if ( $prev_aa  ) {
	    $atom_2_ctr{$prev_aa}= $ctr;
	}
	$ctr = 0;
	$prev_aa = $res_seq;
    }
    $atom_2 {$res_seq}[$ctr][0] = $serial;
    $atom_2 {$res_seq}[$ctr][1] = $x;
    $atom_2 {$res_seq}[$ctr][2] = $y;
    $atom_2 {$res_seq}[$ctr][3] = $z;
    $ctr++;
}

$atom_2_ctr{$prev_aa} = $ctr;


#****************************************************************

$ranks_file = $ranksfile1;
open (RANKS, "<$ranks_file") ||
    die "could not open $ranks_file.\n";
while ( <RANKS> ) {
    next if ( /%/ );
    next if ( ! /\S/ ); # to get rid of empty lines 
    @aux = split;
    if ( $aux[$res_column] !~ '-' ) {
	$rank1{$aux[$res_column]} = $aux[$rank_column] ;
    }
}
close RANKS;
foreach $aa1 ( @chain1 ) {
    if ( ! defined $rank1{$aa1} ){
	die " rank for $aa1 in  $pdb1 not defined\n\n";
    }
}

$ranks_file = $ranksfile2;
open (RANKS, "<$ranks_file") ||
    die "could not open $ranks_file.\n";
while ( <RANKS> ) {
    next if ( /%/ );
    next if ( ! /\S/ ); # to get rid of empty lines 
    @aux = split;
    if ( $aux[$res_column] !~ '-' ) {
	$rank2{$aux[$res_column]} = $aux[$rank_column] ;
    }  
}
close RANKS;
foreach $aa2 ( @chain2 ) {
    if ( ! defined $rank2{$aa2} ){
	die " rank for $aa2 in  $pdb2 not defined\n\n";
    }
}



#****************************************************************

foreach $aa1 ( @chain1 ) {

    foreach $aa2 ( @chain2 ) {


	$r_min = 1000.0;
	for ($ctr1=0; $ctr1<$atom_1_ctr{$aa1}; $ctr1++) {
	    $x1 = $atom_1{$aa1}[$ctr1][1];
	    $y1 = $atom_1{$aa1}[$ctr1][2];
	    $z1 = $atom_1{$aa1}[$ctr1][3];

	    for ($ctr2=0; $ctr2<$atom_2_ctr{$aa2}; $ctr2++) {
		$x2 = $atom_2{$aa2}[$ctr2][1];
		$y2 = $atom_2{$aa2}[$ctr2][2];
		$z2 = $atom_2{$aa2}[$ctr2][3];
		
		$r = ($x1-$x2)*($x1-$x2)+ ($y1-$y2)*($y1-$y2)
		    +($z1-$z2)*($z1-$z2);
		$r = sqrt ($r);
		if ($r <= $r_min ) {
		    $r_min = $r;
		}
	    }
	}
	($r_min > 0) ||
	    die " distance == 0 (?) ... residues: $aa1 $aa2 \n";
	
	$contact_score = 100.0/(1+ abs ($rank1{$aa1}-$rank2{$aa2}));
	if ( $r_min < $CUTOFF_DIST ) {
	    printf  "%6d %6d %8.3f %8.3f  %8.3f  %8.3f \n", 
		    $aa1, $aa2, $r_min, $rank1{$aa1}, $rank2{$aa2}, $contact_score;
	}
	
    }
	
    
}
