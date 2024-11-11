#! /usr/bin/perl -w 


(defined $ARGV[0] && defined $ARGV[1]  ) ||
    die "usage: rmsd.pl  <pdb_name_1> <pdb_name_2> \n.";

$pdbfile1 = $ARGV[0];
$pdbfile2 = $ARGV[1];

$aa_col = 4;


open (PDBFILE1, "<$pdbfile1") ||
    die "could not open $pdbfile1.\n";

open (PDBFILE2, "<$pdbfile2") ||
    die "could not open $pdbfile2.\n";

$aa_col = 5;

$ctr = 0;
while ( <PDBFILE1> ) {
    next if ( ! /^ATOM/  && !/^HETATM/ );
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

$rmsd = 0;
for $ctr ( 0 .. $no_atoms-1) {
    for $i (0..2) {
	$baux = $atom_1[$ctr][$i]-$atom_2[$ctr][$i];    
	$rmsd += $baux*$baux;
    }
}

$rmsd = sqrt ($rmsd/$ctr);

printf " %10.4f ", $rmsd;
