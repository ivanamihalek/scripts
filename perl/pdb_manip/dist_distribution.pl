#! /usr/bin/perl -w 


(defined $ARGV[0] && defined $ARGV[1]  ) ||
    die "usage: rmsd.pl  <pdb_name_1> <pdb_name_2> [calpha/cbeta] \n.";
$cbeta = 0;
$calpha = 0;
$pdbfile1 = $ARGV[0];
$pdbfile2 = $ARGV[1];
(defined $ARGV[2]  &&   $ARGV[2] eq "calpha" ) && ( $calpha = 1 );
(defined $ARGV[2]  &&   $ARGV[2] eq "cbeta" ) && ( $cbeta = 1 );
$aa_col = 4;


open (PDBFILE1, "<$pdbfile1") ||
    die "could not open $pdbfile1.\n";

open (PDBFILE2, "<$pdbfile2") ||
    die "could not open $pdbfile2.\n";

$aa_col = 5;

$ctr = 0;
while ( <PDBFILE1> ) {
    next if ( ! /^ATOM/  && !/^HETATM/ );
    $atom_name = substr $_,  12, 4 ;  $atom_name =~ s/\s//g; 
    next if ( $calpha && $atom_name ne "CA");
    next if ( $cbeta  && $atom_name ne "CB");
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;
    $atom_1[$ctr][0] =  $x;   
    $atom_1[$ctr][1] =  $y;    
    $atom_1[$ctr][2] =  $z;
    $ctr++;
}
$no_atoms1 = $ctr;

$ctr = 0;
while ( <PDBFILE2> ) {
    next if ( ! /^ATOM/  && !/^HETATM/ );
    $atom_name = substr $_,  12, 4 ;  $atom_name =~ s/\s//g; 
    next if ( $calpha && $atom_name ne "CA");
    next if ( $cbeta  && $atom_name ne "CB");
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;
    $atom_2[$ctr][0] =  $x;   
    $atom_2[$ctr][1] =  $y;    
    $atom_2[$ctr][2] =  $z;
    $ctr++;
}
$no_atoms2 = $ctr;

($no_atoms2 == $no_atoms1) ||
    die "no of atoms ($no_atoms1) in $pdbfile1  not equal to the number ($no_atoms2) in $pdbfile2.\n";

$no_atoms = $ctr;

$step = 0.1;
$max_dist = 15.0;
$max_bin = $max_dist/$step;
for $bin_ctr ( 0 .. $max_bin) {
    $population[$bin_ctr] = 0;
}


for $ctr ( 0 .. $no_atoms-1) {
    $dist = 0.0;
    for $i (0..2) {
	$baux = $atom_1[$ctr][$i]-$atom_2[$ctr][$i];    
	$dist += $baux*$baux;
    }
    $dist = sqrt ($dist);
    #print "$ctr   $dist\n";
    for $bin_ctr ( 0 .. $max_bin) {
	if ( $dist < ($bin_ctr+1)*$step ) {
	    $population[$bin_ctr] ++;
	    last;
	} 
    }
}
#exit;

for $bin_ctr ( 0 .. $max_bin) {
    printf "%4d  %8.3f   %8.3f \n",  $bin_ctr, ($bin_ctr+1)*$step, $population[$bin_ctr]/$no_atoms;
}
