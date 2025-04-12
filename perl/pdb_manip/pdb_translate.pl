#! /usr/bin/perl -w 



(@ARGV >= 4 ) ||
    die "Usage: pdb_translate.pl   <pdb_file>  x y z.\n";

$pdbfile = shift @ARGV;
@t = @ARGV;


open ( PDB, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

while ( <PDB> ) {
    if ( ! ( /^ATOM/ || /^HETATM/) ){
	print;
	next;
    }
    chomp;
    $crap = substr ($_, 0, 30);
    $crap2 = substr ($_, 54);
    $x = substr $_, 30, 8;  $x=~ s/\s//g;
    $y = substr $_, 38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8;  $z=~ s/\s//g;

    $x += $t[0];
    $y += $t[1];
    $z += $t[2];
    
    printf  "%30s%8.3f%8.3f%8.3f%s \n",
	   $crap,  $x, $y, $z, $crap2;
   
}
close PDB;


