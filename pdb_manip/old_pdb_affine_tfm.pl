#! /usr/bin/perl -w 



defined ( $ARGV[0])  && defined ( $ARGV[1] ) ||
    die "Usage: pdb_affine_tfm.pl   <pdb_file>  <tfm_file>.\n";

$pdbfile = $ARGV[0];
$tfmfile = $ARGV[1];

open ( TFM, "<$tfmfile") ||
    die "Cno $tfmfile: $!.\n";
# expects input in the format
# 
#$A[0][0]     $A[0][1]   $A[0][2]   $x0
#$A[1][0]     $A[1][1]   $A[1][2]   $y0
#$A[2][0]     $A[2][1]   $A[2][2]   $z0

$i = 0;
while ( <TFM> ) {
    @aux = split;
    for $j ( 0 .. 2) {
	$A[$i][$j] = $aux[$j];
    }
    $t[$i] = $aux[3];
    $i++;
}

close TFM;





=pod
# translation
$x0 =  39.150;
$y0 =  22.487;
$z0 = 118.896;

# rotation
$A[0][0]=   0.037;     $A[0][1]= 0.086;    $A[0][2]=  1.049;
$A[1][0]=  -0.752;     $A[1][1]= 0.678;    $A[1][2]= -0.079; 
$A[2][0]=   0.645;     $A[2][1]= 0.771;    $A[2][2]=  0.036; 
=cut


$avg_x = 0;
$avg_y = 0;
$avg_z = 0;
$ctr = 0;

open ( PDB, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

while ( <PDB> ) {
    next if ( ! /\S/);
    chomp;
    $crap[$ctr] = substr ($_, 0, 30);
    $crap2[$ctr] = substr ($_, 54);
    $x[$ctr] = substr $_,30, 8;  $x[$ctr]=~ s/\s//g;
    $y[$ctr] = substr $_,38, 8;  $y[$ctr]=~ s/\s//g;
    $z[$ctr] = substr $_, 46, 8; $z[$ctr]=~ s/\s//g;
    $avg_x += $x[$ctr];
    $avg_y += $y[$ctr];
    $avg_z += $z[$ctr];
    $ctr++;
   
}
$no_atoms = $ctr;

close PDB;

$avg_x /= $no_atoms;
$avg_y /= $no_atoms;
$avg_z /= $no_atoms;

#printf " %7.3f  %7.3f   %7.3f \n", $avg_x, $avg_y, $avg_z;
#exit;


for $ctr (0 .. $no_atoms-1) {

    # rotate
    $xnew = $A[0][0]*$x[$ctr] +   $A[0][1]*$y[$ctr]  +  $A[0][2]*$z[$ctr];
    $ynew = $A[1][0]*$x[$ctr] +   $A[1][1]*$y[$ctr]  +  $A[1][2]*$z[$ctr];
    $znew = $A[2][0]*$x[$ctr] +   $A[2][1]*$y[$ctr]  +  $A[2][2]*$z[$ctr];
    # translate
    $xnew += $t[0];
    $ynew += $t[1];
    $znew += $t[2];

    printf  "%30s%8.3f%8.3f%8.3f%s \n",
	   $crap[$ctr],  $xnew, $ynew, $znew, $crap2[$ctr];

}

