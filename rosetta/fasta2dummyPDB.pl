#! /usr/bin/perl -w
sub setup_dummy_coords ();

@ARGV ||
    die "Usage:  $0  <fasta (in)> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

$seq = "";
while ( <IF> ) {
    next if ( !/\S/);
    next if ( /^>/ );
    chomp;
    $seq .= uc $_;

}
close IF;

%dummy_coords = ();
setup_dummy_coords();

$seq =~ s/[\s\.\-]//g;

@aas = split "", $seq;

$res_ctr = 0;
$atom_ctr = 0;

$x = 0.0;
$y = 0.0;
$z = 0.0;

foreach $aa (@aas) {
    $res_ctr ++;


    @lines = split "\n", $dummy_coords{$aa};
    foreach $line (@lines) {
	$atom_ctr++;
	$x += 2*(rand()-0.5);
	$y += 2*(rand()-0.5);
	$z += 2*(rand()-0.5);
	(substr $line,30, 8) =  sprintf "%8.3f", $x;
	(substr $line,38, 8) =  sprintf "%8.3f", $y;
	(substr $line,46, 8) =  sprintf "%8.3f", $z;

	(substr $line, 22, 4) = sprintf "%4d", $res_ctr;
	(substr $line, 6, 5) = sprintf "%5d", $atom_ctr;
	print "$line\n";
    }


}



#
######################################################

sub setup_dummy_coords () {

$dummy_coords{"Q"} = 
"ATOM      1  N   GLN A   4       0.000   0.000   0.00   1.00  0.00           N  
ATOM      2  CA  GLN A   4       0.000   0.000   0.00   1.00  0.00           C  
ATOM      3  C   GLN A   4       0.000   0.000   0.00   1.00  0.00           C  
ATOM      4  O   GLN A   4       0.000   0.000   0.00   1.00  0.00           O  
ATOM      5  CB  GLN A   4       0.000   0.000   0.00   1.00  0.00           C  
ATOM      6  CG  GLN A   4       0.000   0.000   0.00   1.00  0.00           C  
ATOM      7  CD  GLN A   4       0.000   0.000   0.00   1.00  0.00           C  
ATOM      8  OE1 GLN A   4       0.000   0.000   0.00   1.00  0.00           O  
ATOM      9  NE2 GLN A   4       0.000   0.000   0.00   1.00  0.00           N  ";
$dummy_coords{"V"} = 
"ATOM     10  N   VAL A   5       0.000   0.000   0.00   1.00  0.00           N  
ATOM     11  CA  VAL A   5       0.000   0.000   0.00   1.00  0.00           C  
ATOM     12  C   VAL A   5       0.000   0.000   0.00   1.00  0.00           C  
ATOM     13  O   VAL A   5       0.000   0.000   0.00   1.00  0.00           O  
ATOM     14  CB  VAL A   5       0.000   0.000   0.00   1.00  0.00           C  
ATOM     15  CG1 VAL A   5       0.000   0.000   0.00   1.00  0.00           C  
ATOM     16  CG2 VAL A   5       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"L"} = 
"ATOM     17  N   LEU A   6       0.000   0.000   0.00   1.00  0.00           N  
ATOM     18  CA  LEU A   6       0.000   0.000   0.00   1.00  0.00           C  
ATOM     19  C   LEU A   6       0.000   0.000   0.00   1.00  0.00           C  
ATOM     20  O   LEU A   6       0.000   0.000   0.00   1.00  0.00           O  
ATOM     21  CB  LEU A   6       0.000   0.000   0.00   1.00  0.00           C  
ATOM     22  CG  LEU A   6       0.000   0.000   0.00   1.00  0.00           C  
ATOM     23  CD1 LEU A   6       0.000   0.000   0.00   1.00  0.00           C  
ATOM     24  CD2 LEU A   6       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"A"} = 
"ATOM     25  N   ALA A   7       0.000   0.000   0.00   1.00  0.00           N  
ATOM     26  CA  ALA A   7       0.000   0.000   0.00   1.00  0.00           C  
ATOM     27  C   ALA A   7       0.000   0.000   0.00   1.00  0.00           C  
ATOM     28  O   ALA A   7       0.000   0.000   0.00   1.00  0.00           O  
ATOM     29  CB  ALA A   7       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"R"} = 
"ATOM     30  N   ARG A   8       0.000   0.000   0.00   1.00  0.00           N  
ATOM     31  CA  ARG A   8       0.000   0.000   0.00   1.00  0.00           C  
ATOM     32  C   ARG A   8       0.000   0.000   0.00   1.00  0.00           C  
ATOM     33  O   ARG A   8       0.000   0.000   0.00   1.00  0.00           O  
ATOM     34  CB  ARG A   8       0.000   0.000   0.00   1.00  0.00           C  
ATOM     35  CG  ARG A   8       0.000   0.000   0.00   1.00  0.00           C  
ATOM     36  CD  ARG A   8       0.000   0.000   0.00   1.00  0.00           C  
ATOM     37  NE  ARG A   8       0.000   0.000   0.00   1.00  0.00           N  
ATOM     38  CZ  ARG A   8       0.000   0.000   0.00   1.00  0.00           C  
ATOM     39  NH1 ARG A   8       0.000   0.000   0.00   1.00  0.00           N  
ATOM     40  NH2 ARG A   8       0.000   0.000   0.00   1.00  0.00           N  ";
$dummy_coords{"K"} = 
"ATOM     41  N   LYS A   9       0.000   0.000   0.00   1.00  0.00           N  
ATOM     42  CA  LYS A   9       0.000   0.000   0.00   1.00  0.00           C  
ATOM     43  C   LYS A   9       0.000   0.000   0.00   1.00  0.00           C  
ATOM     44  O   LYS A   9       0.000   0.000   0.00   1.00  0.00           O  
ATOM     45  CB  LYS A   9       0.000   0.000   0.00   1.00  0.00           C  
ATOM     46  CG  LYS A   9       0.000   0.000   0.00   1.00  0.00           C  
ATOM     47  CD  LYS A   9       0.000   0.000   0.00   1.00  0.00           C  
ATOM     48  CE  LYS A   9       0.000   0.000   0.00   1.00  0.00           C  
ATOM     49  NZ  LYS A   9       0.000   0.000   0.00   1.00  0.00           N  ";
$dummy_coords{"W"} = 
"ATOM     50  N   TRP A  10       0.000   0.000   0.00   1.00  0.00           N  
ATOM     51  CA  TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     52  C   TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     53  O   TRP A  10       0.000   0.000   0.00   1.00  0.00           O  
ATOM     54  CB  TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     55  CG  TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     56  CD1 TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     57  CD2 TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     58  NE1 TRP A  10       0.000   0.000   0.00   1.00  0.00           N  
ATOM     59  CE2 TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     60  CE3 TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     61  CZ2 TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     62  CZ3 TRP A  10       0.000   0.000   0.00   1.00  0.00           C  
ATOM     63  CH2 TRP A  10       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"P"} = 
"ATOM     75  N   PRO A  12       0.000   0.000   0.00   1.00  0.00           N  
ATOM     76  CA  PRO A  12       0.000   0.000   0.00   1.00  0.00           C  
ATOM     77  C   PRO A  12       0.000   0.000   0.00   1.00  0.00           C  
ATOM     78  O   PRO A  12       0.000   0.000   0.00   1.00  0.00           O  
ATOM     79  CB  PRO A  12       0.000   0.000   0.00   1.00  0.00           C  
ATOM     80  CG  PRO A  12       0.000   0.000   0.00   1.00  0.00           C  
ATOM     81  CD  PRO A  12       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"T"} = 
"ATOM     91  N   THR A  14       0.000   0.000   0.00   1.00  0.00           N  
ATOM     92  CA  THR A  14       0.000   0.000   0.00   1.00  0.00           C  
ATOM     93  C   THR A  14       0.000   0.000   0.00   1.00  0.00           C  
ATOM     94  O   THR A  14       0.000   0.000   0.00   1.00  0.00           O  
ATOM     95  CB  THR A  14       0.000   0.000   0.00   1.00  0.00           C  
ATOM     96  OG1 THR A  14       0.000   0.000   0.00   1.00  0.00           O  
ATOM     97  CG2 THR A  14       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"F"} = 
"ATOM     98  N   PHE A  15       0.000   0.000   0.00   1.00  0.00           N  
ATOM     99  CA  PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    100  C   PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    101  O   PHE A  15       0.000   0.000   0.00   1.00  0.00           O  
ATOM    102  CB  PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    103  CG  PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    104  CD1 PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    105  CD2 PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    106  CE1 PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    107  CE2 PHE A  15       0.000   0.000   0.00   1.00  0.00           C  
ATOM    108  CZ  PHE A  15       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"D"} = 
"ATOM    114  N   ASP A  17       0.000   0.000   0.00   1.00  0.00           N  
ATOM    115  CA  ASP A  17       0.000   0.000   0.00   1.00  0.00           C  
ATOM    116  C   ASP A  17       0.000   0.000   0.00   1.00  0.00           C  
ATOM    117  O   ASP A  17       0.000   0.000   0.00   1.00  0.00           O  
ATOM    118  CB  ASP A  17       0.000   0.000   0.00   1.00  0.00           C  
ATOM    119  CG  ASP A  17       0.000   0.000   0.00   1.00  0.00           C  
ATOM    120  OD1 ASP A  17       0.000   0.000   0.00   1.00  0.00           O  
ATOM    121  OD2 ASP A  17       0.000   0.000   0.00   1.00  0.00           O  ";
$dummy_coords{"G"} = 
"ATOM    136  N   GLY A  20       0.000   0.000   0.00   1.00  0.00           N  
ATOM    137  CA  GLY A  20       0.000   0.000   0.00   1.00  0.00           C  
ATOM    138  C   GLY A  20       0.000   0.000   0.00   1.00  0.00           C  
ATOM    139  O   GLY A  20       0.000   0.000   0.00   1.00  0.00           O  ";
$dummy_coords{"E"} = 
"ATOM    149  N   GLU A  22       0.000   0.000   0.00   1.00  0.00           N  
ATOM    150  CA  GLU A  22       0.000   0.000   0.00   1.00  0.00           C  
ATOM    151  C   GLU A  22       0.000   0.000   0.00   1.00  0.00           C  
ATOM    152  O   GLU A  22       0.000   0.000   0.00   1.00  0.00           O  
ATOM    153  CB  GLU A  22       0.000   0.000   0.00   1.00  0.00           C  
ATOM    154  CG  GLU A  22       0.000   0.000   0.00   1.00  0.00           C  
ATOM    155  CD  GLU A  22       0.000   0.000   0.00   1.00  0.00           C  
ATOM    156  OE1 GLU A  22       0.000   0.000   0.00   1.00  0.00           O  
ATOM    157  OE2 GLU A  22       0.000   0.000   0.00   1.00  0.00           O  ";
$dummy_coords{"H"} = 
"ATOM    158  N   HIS A  23       0.000   0.000   0.00   1.00  0.00           N  
ATOM    159  CA  HIS A  23       0.000   0.000   0.00   1.00  0.00           C  
ATOM    160  C   HIS A  23       0.000   0.000   0.00   1.00  0.00           C  
ATOM    161  O   HIS A  23       0.000   0.000   0.00   1.00  0.00           O  
ATOM    162  CB  HIS A  23       0.000   0.000   0.00   1.00  0.00           C  
ATOM    163  CG  HIS A  23       0.000   0.000   0.00   1.00  0.00           C  
ATOM    164  ND1 HIS A  23       0.000   0.000   0.00   1.00  0.00           N  
ATOM    165  CD2 HIS A  23       0.000   0.000   0.00   1.00  0.00           C  
ATOM    166  CE1 HIS A  23       0.000   0.000   0.00   1.00  0.00           C  
ATOM    167  NE2 HIS A  23       0.000   0.000   0.00   1.00  0.00           N  ";
$dummy_coords{"N"} = 
"ATOM    208  N   ASN A  30       0.000   0.000   0.00   1.00  0.00           N  
ATOM    209  CA  ASN A  30       0.000   0.000   0.00   1.00  0.00           C  
ATOM    210  C   ASN A  30       0.000   0.000   0.00   1.00  0.00           C  
ATOM    211  O   ASN A  30       0.000   0.000   0.00   1.00  0.00           O  
ATOM    212  CB  ASN A  30       0.000   0.000   0.00   1.00  0.00           C  
ATOM    213  CG  ASN A  30       0.000   0.000   0.00   1.00  0.00           C  
ATOM    214  OD1 ASN A  30       0.000   0.000   0.00   1.00  0.00           O  
ATOM    215  ND2 ASN A  30       0.000   0.000   0.00   1.00  0.00           N  ";
$dummy_coords{"S"} = 
"ATOM    228  N   SER A  33       0.000   0.000   0.00   1.00  0.00           N  
ATOM    229  CA  SER A  33       0.000   0.000   0.00   1.00  0.00           C  
ATOM    230  C   SER A  33       0.000   0.000   0.00   1.00  0.00           C  
ATOM    231  O   SER A  33       0.000   0.000   0.00   1.00  0.00           O  
ATOM    232  CB  SER A  33       0.000   0.000   0.00   1.00  0.00           C  
ATOM    233  OG  SER A  33       0.000   0.000   0.00   1.00  0.00           O  ";
$dummy_coords{"I"} = 
"ATOM    257  N   ILE A  37       0.000   0.000   0.00   1.00  0.00           N  
ATOM    258  CA  ILE A  37       0.000   0.000   0.00   1.00  0.00           C  
ATOM    259  C   ILE A  37       0.000   0.000   0.00   1.00  0.00           C  
ATOM    260  O   ILE A  37       0.000   0.000   0.00   1.00  0.00           O  
ATOM    261  CB  ILE A  37       0.000   0.000   0.00   1.00  0.00           C  
ATOM    262  CG1 ILE A  37       0.000   0.000   0.00   1.00  0.00           C  
ATOM    263  CG2 ILE A  37       0.000   0.000   0.00   1.00  0.00           C  
ATOM    264  CD1 ILE A  37       0.000   0.000   0.00   1.00  0.00           C  ";
$dummy_coords{"Y"} = 
"ATOM    290  N   TYR A  41       0.000   0.000   0.00   1.00  0.00           N  
ATOM    291  CA  TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    292  C   TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    293  O   TYR A  41       0.000   0.000   0.00   1.00  0.00           O  
ATOM    294  CB  TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    295  CG  TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    296  CD1 TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    297  CD2 TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    298  CE1 TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    299  CE2 TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    300  CZ  TYR A  41       0.000   0.000   0.00   1.00  0.00           C  
ATOM    301  OH  TYR A  41       0.000   0.000   0.00   1.00  0.00           O  ";
$dummy_coords{"C"} = 
"ATOM    460  N   CYS A  64       0.000   0.000   0.00   1.00  0.00           N  
ATOM    461  CA  CYS A  64       0.000   0.000   0.00   1.00  0.00           C  
ATOM    462  C   CYS A  64       0.000   0.000   0.00   1.00  0.00           C  
ATOM    463  O   CYS A  64       0.000   0.000   0.00   1.00  0.00           O  
ATOM    464  CB  CYS A  64       0.000   0.000   0.00   1.00  0.00           C  
ATOM    465  SG  CYS A  64       0.000   0.000   0.00   1.00  0.00           S  ";
$dummy_coords{"M"} = 
"ATOM    978  N   MET A 130       0.000   0.000   0.00   1.00  0.00           N  
ATOM    979  CA  MET A 130       0.000   0.000   0.00   1.00  0.00           C  
ATOM    980  C   MET A 130       0.000   0.000   0.00   1.00  0.00           C  
ATOM    981  O   MET A 130       0.000   0.000   0.00   1.00  0.00           O  
ATOM    982  CB  MET A 130       0.000   0.000   0.00   1.00  0.00           C  
ATOM    983  CG  MET A 130       0.000   0.000   0.00   1.00  0.00           C  
ATOM    984  SD  MET A 130       0.000   0.000   0.00   1.00  0.00           S  
ATOM    985  CE  MET A 130       0.000   0.000   0.00   1.00  0.00           C  ";


}
