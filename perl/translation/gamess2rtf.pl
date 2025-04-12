#! /usr/bin/perl -w 
# turn small pdb file into rtf to be used in Charmm
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# 1) read coordinates from gamess output 
# 2) read gamess output 
#    2a) figure out which pairs bonded and how strongly
#    2b) figure out which atoms hydrophobic
#    2c) read in the charges
# 3) detect cycles
# 4) dyhedral angles
# 5) assign types
# 6) output

# BOHR =  0.529177249d0 ANGSTROM 


$esp = 0; # use esp chrages (vs.mullikan)

defined ( $ARGV[0] ) ||
    die "Usage: pdb2rtf.pl  <gamess_output>.\n";
$gms = $ARGV[0];
open ( IF, "<$gms" ) ||
    die "Cno $gms:$!.\n";

#########################################################
#          READ COORDINATES
#########################################################

$bohr2angstrom = 0.5291772;

while ( <IF> ) {
    last if ( /COORDINATES \(BOHR\)/);
}
<IF>; # skip a line

$ctr = 0;
while ( <IF> ) {
    last if ( ! /\S/ );
    chomp;
    ($name, $mass, $x, $y, $z) = split;

    $atom_type [$ctr] = substr $name, 0, 1;
    $coord[$ctr][0] = $x*$bohr2angstrom;
    $coord[$ctr][1] = $y*$bohr2angstrom;
    $coord[$ctr][2] = $z*$bohr2angstrom;
    $ctr++;
}

#rewind
seek IF, 0, 0;
$mass = ""; # so perl doesn't whine

$max_atom = $ctr-1;

for $atom_no (0 .. $max_atom ) {
    printf  "%6d   %1s ",  $atom_no, $atom_type[$atom_no];
    for $crd (0..2) {
	printf  "%8.3f ",  $coord[$atom_no][$crd];
    }
    print "\n";
}

# distance matrix: ---> do I need it?
for $atom_1 (0 .. $max_atom-1 ) {
    for $atom_2 ($atom_1+1 .. $max_atom ) {
	$d2 = 0.0;
	for $crd (0..2) {
	    $tmp = $coord[$atom_1][$crd]-$coord[$atom_2][$crd];
	    $d2 += $tmp*$tmp;
	}
	$distance[$atom_1][$atom_2] = sqrt ($d2);
    }
}


#########################################################
#          READ BOND ORDER
#########################################################
$no_bonds = 0;
for $atom_1 (0 .. $max_atom ) {
    for $atom_2 (0.. $max_atom ) {
	$adj [$atom_1][$atom_2] = 0;
    }
}

while ( <IF> ) {
    last if  (/ATOM PAIR DIST  ORDER/);
}
while ( <IF> ) {
    last if ( ! /\S/ );
    @aux = split;
    $no_repeats = ($#aux+1)/4;
    for $ctr ( 0 .. $no_repeats-1) {
	$here = $ctr*4;
	$there = $here+3;
	($atom_1, $atom_2, $dist, $bo) = @aux[ $here .. $there];	
	print " $atom_1   $atom_2   $dist  $bo \n";
	if ( $bo > 0.1 ) { # empirical cutoff I found somewhere
	    $atom_1 --;
	    $atom_2 --;
	    $strength = 1;
	    if ( $bo > 2.5 ) {
		$strength = 3;
	    } elsif ( $bo > 1.5 ) {
		$strength = 2;
	    }

	    $adj [$atom_1][$atom_2] = $strength;
	    $adj [$atom_2][$atom_1] = $strength;
	    $no_bonds ++;
	}
    }
}
=pod
exit;

for $atom_1 ( 0 .. 41 ) {
    for $atom_2 ( $atom_1 .. 42 ) {
	print " $atom_1   $atom_2  $adj[$atom_1][$atom_2]\n";
    }
}
exit;
=cut
#rewind
seek IF, 0, 0;
$dist = "";
print "\nno bonds:  $no_bonds\n\n";

#########################################################
#          CYCLE DETECTION
#########################################################

for $atom_1 (0 .. $max_atom ) {
    $no_nbrs[$atom_1] = 0;
    for $atom_2 ( 0 .. $max_atom ) {
	next if ( $atom_1 == $atom_2 );
	if (  $adj [$atom_1][$atom_2] ) {
	    $nbr [$atom_1][$no_nbrs[$atom_1]] = $atom_2; 
	    $no_nbrs[$atom_1]++;
	}
    }
}
for $atom_1 (0 .. $max_atom ) {
    print "atom: $atom_1   no nbrs: $no_nbrs[$atom_1]  nbrs: ";
    for $ctr ( 0 .. $no_nbrs[$atom_1]-1) {
	print "$nbr[$atom_1][$ctr]  ";
    }
    print "\n";
}

@visited = ();
@cyclops= ();
for $atom_1 (0 .. $max_atom ) {
    $cyclops [ $atom_1 ] = 0;
    $visited[ $atom_1 ] = 0;
}

@path = ();
%found = ();
dfs (0, -1);



#########################################################
#          READ CHARGE
#########################################################
if ( $esp) {
    $chg_found = 0;
    while ( <IF> ) {
	if  (/ NET CHARGES/) {
	    $chg_found = 1;
	    last;
	}
    }
    if ( ! $chg_found ) {
	die "ESP charges not found in $gms.\n"; 
    }
    <IF>; <IF>; <IF>;
    $ctr = 0;
    while ( <IF> ) {
	last if (  ! /\d/ );
	chomp;
	@aux= split;
	$chg =  $aux[1];
	$charge[$ctr] = $chg; 
	$ctr++;
    }
    


} else {
    while ( <IF> ) {
	last if  (/TOTAL MULLIKEN AND LOWDIN ATOMIC POPULATIONS/);
    }
    <IF>;
    $ctr = 0;
    while ( <IF> ) {
	last if (  ! /\S/ );
	chomp;
	@aux= split;
	$chg =  $aux[3];
	$charge[$ctr] = $chg; 
	$ctr++;
    }
}
#rewind
seek IF, 0, 0;
$esd = "";

#########################################################
#          HYDROGEN BOND PROPENSITY FROM CHARGE
#########################################################
for $atom_1 (0 .. $max_atom ) {
    $hbond[$atom_1] = "none";
    if (  $atom_type [$atom_1] =~ 'H' && 'H'  =~  $atom_type [$atom_1] ) {
	if ( $charge[$atom_1] > 0.25 ) {
	    $hbond[$atom_1]= "donor";
	} 
    } elsif (  $charge[$atom_1] < -0.2 ) {
	    $hbond[$atom_1]= "acceptor";
    }
}



#########################################################
#          ASSIGN UNIQUE NAMES
#########################################################
undef %found;
# first take care of heavy atoms
for $atom_1 (0 .. $max_atom ) {
    if ( $atom_type [$atom_1] =~ 'H' && length ($atom_type [$atom_1]) == 1  ) {
	$new_name[$atom_1] = "";
    } else {
	if ( defined $found{  $atom_type [$atom_1] } ) {
	    $found{  $atom_type [$atom_1] } ++;
	} else {
	    $found{  $atom_type [$atom_1] } = 1;
	}
	$letter = chr(64+$found{  $atom_type [$atom_1] });
	$new_name[$atom_1] = $atom_type [$atom_1]. $letter;
    }
    
}

# then of hydrogens
for $atom_1 (0 .. $max_atom ) {
    if ( $atom_type [$atom_1] =~ 'H' && length ($atom_type [$atom_1]) == 1  ) {
	$heavy = $nbr [$atom_1][0];
	$tmp_name = "H".$new_name[$heavy];
	if ( defined $found{$tmp_name} ) {
	    $found{$tmp_name} ++;
	} else {
	    $found{$tmp_name} = 1;
	}
	$new_name[$atom_1] = $tmp_name.$found{$tmp_name};
    } else {
    }
}

#########################################################
#          ASSIGN ATOM TYPES
#########################################################

# first find "special" carbons (group anchors)
@special = ();
special_properties();

for $atom_1 (0 .. $max_atom ) {
    $charmm_type[$atom_1] = "";
    $charmm_type_no[$atom_1] = 0;
    ($charmm_type[$atom_1], $charmm_type_no[$atom_1], $mass[$atom_1])  
	= assign_type ( $atom_1);
}

#########################################################
#          OUTPUT
#########################################################

for $atom_1 (0 .. $max_atom ) {
    printf "%5d  %2s   %8s   %3d  %3d   %8.4f  %12s   %8s  %4d  %8.4f\n",
    $atom_1,   $atom_type [$atom_1],  $new_name[$atom_1],  
    $no_nbrs[$atom_1], 
    $cyclops[$atom_1], $charge[$atom_1],$hbond[$atom_1],
     $charmm_type[$atom_1], $charmm_type_no[$atom_1], $mass[$atom_1];
}

#########################################################
#          OUTPUT RTF CARD
#########################################################

@aux =  split ('\.', $gms);
$aux[ $#aux] = "rtf";
$rtfname =  join ('.', @aux);
open ( RTF, ">$rtfname") || 
    die "Cno $rtfname: $!.\n";


close RTF;

#########################################################
#          OUTPUT NO-FRILLS PDB
#########################################################

@aux =  split ('\.', $gms);
$aux[ $#aux] = "pdb";
$pdbname =  join ('.', @aux);

open ( PDB, ">$pdbname") ||
    die "Cno $pdbname: $!.\n";

for $atom_1 (0 .. $max_atom ) {
    $record = "ATOM";
    $serial = $atom_1+1;
    $name =  $new_name[$atom_1];
    $alt_loc = " ";
    $res_name = uc substr ($aux[0], 0, 3);
    $chain_id = " ";
    $res_seq  = "1";
    $i_code = " ";
    $x = $coord[$atom_1][0];
    $y = $coord[$atom_1][1];
    $z = $coord[$atom_1][2];

 
    printf  PDB   "%-6s%5d %4s%1s%-3s %1s%4d %1s  %8.3f%8.3f%8.3f\n", 
	$record,   $serial,  $name,   $alt_loc,   $res_name,
	$chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;
    
}

close PDB;


###################################################################################
###################################################################################
###################################################################################
#  DEPTH-FIRST  SEARCH SUBROUTINE
###################################################################################

sub dfs () { 
    my $atom = $_[0];
    my $predecessor =  $_[1];
    if (  $visited [$atom] ) {
	# uniqueness check:
	@aux = ();
	$ctr = $#path+1;
	do {
	    $ctr--;
	    push @aux, $path[$ctr];
	} while ( $path[$ctr] != $atom);
	$aux_string = join ('', sort @aux);
	if ( defined $found{$aux_string} ) {
	} else {
	    $found{$aux_string} = 1;
	    #what is the length of the path?
	    print "cycle !  ($atom, $predecessor) \n";
	    $length = 0;
	    $ctr = $#path+1;
	    do {
		$ctr--;
		print " $path[$ctr] ";
		$length++;
	    } while ( $path[$ctr] != $atom);
	    print "  .... $length   \n";

	    #strore the cyclycity info
	    $ctr = $#path+1;
	    do {
		$ctr--;
		$cyclops[ $path[$ctr] ] = $length;
	    } while ( $path[$ctr] != $atom);

	}
	return;
    }
    $visited [$atom] = 1;
    push @path, $atom;
    for $ctr ( 0 .. $no_nbrs[$atom]-1) {
	next if ( $nbr[$atom][$ctr] == $predecessor);
	dfs (  $nbr[$atom][$ctr], $atom );
    } 
    $visited [$atom] = 0;
    $ret = pop @path;
    if ( $ret != $atom ) {
	die "Path error.\n";
    }
    
}

#annotate eacy atom with $ring = 0, 5,6 etc
# (if not a part of a ring, part of a 5-membered ring, a part of a 6 
# mebered ring, and so on)

###################################################################################
###################################################################################
###################################################################################
#   SUBROUTINE TO FIND AND DENOTE SPECIAL ATOMS
###################################################################################

 sub special_properties() {
     my $atom;
    
     for $atom (0 .. $max_atom ) {
         # see what the nighbors are
         $hydro = 0;
         $carbo = 0;
         $oxy  = 0;
         $fluoro  = 0;
	 $thio  = 0;
         for $ctr (0 .. $no_nbrs[$atom]-1) {
	     $neighbor = $nbr[$atom][$ctr];
	     $nbrtype =  $atom_type[$neighbor];
	     if ( $nbrtype =~ "H" ) {
		 $hydro++;
	     } elsif ( $nbrtype =~ "C" ) {
		 $carbo ++;
	     } elsif ( $nbrtype =~ "F" ) {
		 $fluoro ++;
	     } elsif ( $nbrtype =~ "O" ) {
		 $oxy ++;
	     } elsif ( $nbrtype =~ "S" ) {
		 $thio ++;
	     }
	 }  
	 $special[$atom] = "";
	 if ( $fluoro ) {
	     $special[$atom] .= "F".$fluoro;
	 }       
 	 if ( $hydro ) {
	     $special[$atom] .= "H".$hydro;
	 }       
 	 if ( $carbo ) {
	     $special[$atom] .= "C".$carbo;
	 }       
 	 if ( $oxy ) {
	     $special[$atom] .= "O".$oxy;
	 }       
 	 if ( $thio ) {
	     $special[$atom] .= "S".$thio;
	 }       
     }

 }



###################################################################################
###################################################################################
###################################################################################
#   ATOM TYPE ASSIGNMENT  SUBROUTINE
###################################################################################

sub assign_type () {
    #uses info about neighbors from the main function
    my $atom = $_[0];
    my $atom_type = $atom_type[$atom];
    my $ctr;
    #MASS    99 DUM    0.00000 H ! dummy atom
    my $type = "DUM", $number = 99, $mass = 0.0;

    $hydro = 0;
    $carbo = 0;
    $oxy  = 0;
    $fluoro  = 0;
    $thio  = 0;

    if ( $special[$atom] =~ /H(\d)/ ) {
	$hydro = $1;
    }
    if ( $special[$atom] =~ /C(\d)/ ) {
	$carbo = $1;
    }
    if ( $special[$atom] =~ /O(\d)/ ) {
	$oxy  = $1;
    }
    if ( $special[$atom] =~ /F(\d)/ ) {
	$fluoro  = $1;
    }
    if ( $special[$atom] =~ /S(\d)/ ) {
	$thio  = $1;
    }
 
   
    if (  $atom_type =~ "H" && length ($atom_type) == 1 ) {
	$heavy = $nbr[$atom][0];
	if ( $hbond[$atom_1] =~ "donor" ) { # takes precedence over "aromatic"
	    #MASS     1 H      1.00800 H ! polar H
	    $type = "H";
	    $number = 1;
	}   elsif ( $cyclops[$heavy] ) {
	    #MASS     5 HP     1.00800 H ! aromatic H
	    $type = "HP";
	    $number = 5;
	} else{
	    #MASS     3 HA     1.00800 H ! nonpolar H
	    $type =  "HA";
	    $number = 3;
	}
	# we don't expect to encounter the following types:
	#MASS     2 HC     1.00800 H ! N-ter H
        #MASS     4 HT     1.00800 H ! TIPS3P WATER HYDROGEN
        #MASS     6 HB     1.00800 H ! backbone H
        #MASS     7 HR1    1.00800 H ! his he1, (+) his HG,HD2
        #MASS     8 HR2    1.00800 H ! (+) his HE1
        #MASS     9 HR3    1.00800 H ! neutral his HG, HD2
	$mass = 1.00800;
    } elsif  (  $atom_type =~ "C" && length ($atom_type) == 1 ){
	if ( $cyclops[$atom] ) {
        #MASS    21 CA    12.01100 C ! aromatic C
	    $type = "CA";
	    $number = 21;
	} else {
	    if ( $fluoro ) {
		if ($fluoro == 1 ) {
		    #Mass  70  CF1  12.01100 ! monofluoromethyl
		    $type = "CF1";
		    $number = 170;
		} elsif  ($fluoro == 2 ) {
		    #Mass  71  CF2  12.01100 ! difluoromethyl
		    $type = "CF2";
		    $number = 171;
		} elsif  ($fluoro == 3 ) {
		    #Mass  72  CF3  12.01100 ! trifluoromethyl
		    $type = "CF2";
		    $number = 172;
		}
	    } elsif ( $no_nbrs[$atom] == 4 ) {
		#sp3 hybridization, tetragonal
		if ( $thio ) {
		    #MASS    38 CS    12.01100 C ! thiolate carbon
		    $type = "CS";
		    $number = 38;
		} elsif ( $hydro == 1 ) {
		    #MASS    22 CT1   12.01100 C ! aliphatic sp3 C for CH
		    $type = "CT1";
		    $number = 22;
		} elsif ( $hydro == 2 ) {
		    #MASS    23 CT2   12.01100 C ! aliphatic sp3 C for CH2
		    $type = "CT2";
		    $number = 23;
		} elsif ( $hydro == 3 ) {
		    #MASS    24 CT3   12.01100 C ! aliphatic sp3 C for CH3
		    $type = "CT3";
		    $number = 24;
		} else { #???????
		}
	    } elsif (  $no_nbrs[$atom] == 3 ) {
		#sp2 hybridization, planar
		if ( $carbo ) {
		    if ( $hydro == 1) {
			#MASS    39 CE1   12.01100 C ! for alkene; RHC=CR (sp2)
			$type = "CE1";
			$number = 39;
		    } elsif ($hydro == 2) {
			#MASS    40 CE2   12.01100 C ! for alkene; H2C=CR (sp2)
			$type = "CE2";
			$number = 40;
		    }
		} else {  #???????
		}
		
	    } else {
		die " C with less than 3 neighbors ?! (atom nr $atom).\n"; 
	    }
	} 

	# we don't expect to encounter the following types:
        #MASS    20 C     12.01100 C ! carbonyl C, peptide backbone
        #MASS    25 CPH1  12.01100 C ! his CG and CD2 carbons
        #MASS    26 CPH2  12.01100 C ! his CE1 carbon
        #MASS    27 CPT   12.01100 C ! trp C between rings
        #MASS    28 CY    12.01100 C ! TRP C in pyrrole ring
        #MASS    29 CP1   12.01100 C ! tetrahedral C (proline CA)
        #MASS    30 CP2   12.01100 C ! tetrahedral C (proline CB/CG)
        #MASS    31 CP3   12.01100 C ! tetrahedral C (proline CD)
        #MASS    32 CC    12.01100 C ! carbonyl C, asn,asp,gln,glu,cter,ct2
        #MASS    33 CD    12.01100 C ! carbonyl C, pres aspp,glup,ct1
        #MASS    34 CPA   12.01100 C ! heme alpha-C
        #MASS    35 CPB   12.01100 C ! heme beta-C
        #MASS    36 CPM   12.01100 C ! heme meso-C
        #MASS    37 CM    12.01100 C ! heme CO carbon
	$mass =  12.01100;
    } elsif  (  $atom_type =~ "N" && length ($atom_type) == 1 ){
  	if ( $cyclops[$atom] ) {
	    if ( $hydro == 1 ) {
		#MASS    51 NR1   14.00700 N ! neutral his protonated ring nitrogen
		# this will have to double as any N in a  ring w proton
		$type = "NR1";
		$number = 51;
	    } else {
		#MASS    52 NR2   14.00700 N ! neutral his unprotonated ring nitrogen
		$type = "NR2";
		$number = 52;
	    }
	} elsif ( $hydro == 1 ) {
	    if ( $carbo == 2 ) {
		#MASS    57 NC2   14.00700 N ! guanidinium nitroogen
		$type = "NC2";
		$number = 57;
		
	    } else {
		#MASS    54 NH1   14.00700 N ! peptide nitrogen
		$type = "NH1";
		$number = 54;
 	    }
	    
	 } elsif ( $hydro == 2 ) {
	    #MASS    55 NH2   14.00700 N ! amide nitrogen
	    $type = "NH2";
	    $number = 55;
	} elsif ( $hydro == 3 ) {
	    #MASS    56 NH3   14.00700 N ! ammonium nitrogen
	    $type = "NH3";
	    $number = 56;
	} else { #??????????
	}
	# we don't expect to encounter the following types:
        #MASS    50 N     14.00700 N ! proline N
        #MASS    53 NR3   14.00700 N ! charged his ring nitrogen
        #MASS    58 NY    14.00700 N ! TRP N in pyrrole ring
        #MASS    59 NP    14.00700 N ! Proline ring NH2+ (N-terminal)
        #MASS    60 NPH   14.00700 N ! heme pyrrole N
	$mass = 14.00700;
    } elsif  (  $atom_type =~ "O" && length ($atom_type) == 1 ){ 
	# is it carboxylate or ester oxygen?
	$carboxyl = 0;
	$ester  = 0;
	for $ctr ( 0 ..  $no_nbrs [$atom]-1 ) {
	    $carbon = $nbr[$atom][$ctr];
	    last if ( $atom_type[$carbon] =~ "C");
	}

	$special[$carbon] =~ /O(\d)/;
	$oxy_nbr = $1;
	
	if ( $oxy_nbr == 2 && ( $no_nbrs[ $nbr[$carbon][0] ]+$no_nbrs[ $nbr[$carbon][1] ] ) == 3) {
	    
	    for $ctr ( 0 .. 1 ) {
		if ( $no_nbrs[ $nbr[$carbon][$ctr] ] == 2 ) {
		    if ( $nbr[ $nbr[$carbon][$ctr] ] [0] == $carbon ) {
			$radical = $atom_type[ $nbr[ $nbr[$carbon][$ctr] ] [0] ];
		    } else {
			$radical = $atom_type[ $nbr[ $nbr[$carbon][$ctr] ] [1] ];
		    }
		    if ( $radical =~  "H")  {
			$carboxyl = 1;
		    } else {
			$ester = 1;
		    }
		}
	    }
	}
	if ($carboxyl ) { 
	    #MASS    72 OC    15.99900 O ! carboxylate oxygen
	    $type = "OC";
	    $number = 72;
	} elsif  ( $ester) {	    
	    #MASS    74 OS    15.99940 O ! ester oxygen
	    $type = "OS";
	    $number = 74;
	} elsif ( $no_nbrs[$atom] == 1 && $carbo && $adj[$atom][$carbon] == 2) {
	    #MASS    70 O     15.99900 O ! carbonyl oxygen
	    $type = "O";
	    $number = 70;
	} elsif ( $no_nbrs[$atom] == 2 && $hydro ) {
	    #MASS    73 OH1   15.99900 O ! hydroxyl oxygen
	    $type = "OH1";
	    $number = 73;
	    
	} else { # for now, make ester the default
	    #MASS    74 OS    15.99940 O ! ester oxygen
	    $type = "OS";
	    $number = 74;
	}
	# we don't expect to encounter the following types:
	#MASS    71 OB    15.99900 O ! carbonyl oxygen in acetic acid - leave this for another time
	#MASS    75 OT    15.99940 O ! TIPS3P WATER OXYGEN
	#MASS    76 OM    15.99900 O ! heme CO/O2 oxygen
	$mass = 15.99900 ;
    } elsif  (  $atom_type =~ "S" && length ($atom_type) == 1 ){
	if ( $no_nbrs[$atom] == 2 && ( $atom_type [ $nbr[$atom][0] ]  =~ "H"  ||  $atom_type [ $nbr[$atom][1] ]  =~ "H" )) {
	    #MASS    83 SS    32.06000 S ! thiolate sulfur
	    $type = "SS";
	    $number = 83;
	} else {
	    #MASS    81 S     32.06000 S ! sulphur
	    $type = "S";
	    $number = 81;
	}
        #MASS    82 SM    32.06000 S ! sulfur C-S-S-C type - other time
 	$mass = 32.06000;
    } elsif  (  $atom_type =~ "F" && length ($atom_type) == 1 ){
	if ( $no_nbrs[$atom] == 1 ) {
	    $neighbor = $nbr[$atom][0];
	    $nbrtype =  $atom_type[$neighbor];
	    if ( $nbrtype =~ "C")  {
		$special[$neighbor] =~ /F(\d)/;
		if ( $1 == 1) {
		    #Mass  186  F1   18.99800 ! Fluorine, monofluoro
		    $type = "F1";
		    $number = 186;
		} elsif ( $1 == 2) {
		    #Mass  187  F2   18.99800 ! Fluorine, difluoro
		    $type = "F2";
		    $number = 187;
		} elsif ( $1 == 3) {
		    #Mass  188  F3   18.99800 ! Fluorine, trifluoro
		    $type = "F3";
		    $number = 188;
		}
	    }
	} else {
	}
	$mass = 18.998400;
    } else {
    }


    if ( ! $number ) {
        die " I don't have parametrization for config of  atom  $atom\n";
    }
    

    return ($type, $number, $mass);

}
