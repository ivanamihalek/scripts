#! /usr/bin/perl -w 
# turn small pdb file into rtf to be used in Charmm
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# 1) read pdb
# 2) read gamess output 
#    2a) figure out which pairs bonded and how strongly
#    2b) figure out which atoms hydrophobic
#    2c) read in the charges
# 3) detect cycles
# 4) dyhedral angles
# 5) assign types
# 6) output


sub dfs ();

#########################################################
#          READ PDB
#########################################################

defined ( $ARGV[0] ) ||
    die "Usage: pdb2rtf.pl  <pdb_file>.\n";
$pdbfile = $ARGV[0];

open ( IF, "<$pdbfile" ) ||
    die "Cno $pdbfile:$!.\n";

while ( <IF> ) {
    next if ( ! /^ATOM/ );

    $record = substr $_, 0, 6;  $record =~ s/\s//g;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $name = substr $_,  12, 4 ;  $name =~ s/\s//g;
    $alt_loc  = substr $_, 16, 1 ;  $alt_loc =~ s/\s//g;
    $res_name = substr $_, 17, 3; $res_name=~ s/\s//g;
    $chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;

    if ( ! defined $min_serial ) {
	$min_serial =  $serial;
    }

    $new_serial =  $serial - $min_serial;
    $atom_type [$new_serial] = substr $name, 0, 1;
    if ( $atom_type [$new_serial] =~ 'A' ) {
	$atom_type [$new_serial] ='C';
    }
    $coord[$new_serial][0] = $x;
    $coord[$new_serial][1] = $y;
    $coord[$new_serial][2] = $z;
}


$max_atom = $new_serial;

for $atom_no (0 .. $max_atom ) {
    printf  "%6d   %1s ",  $atom_no, $atom_type[$atom_no];
    for $crd (0..2) {
	printf  "%8.3f ",  $coord[$atom_no][$crd];
    }
    print "\n";
}


# distance matrix:
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
#          READ GAMESS
#########################################################


# adjacency matrix - this should be replaced by actual bonding info
$CUTOFF_DIST = 1.7;
$no_bonds = 0;
for $atom_1 (0 .. $max_atom ) {
    $adj [$atom_1][$atom_1] = 0;
    for $atom_2 ($atom_1+1 .. $max_atom ) {
	if ( $distance[$atom_1][$atom_2] < $CUTOFF_DIST ) {
	    $adj [$atom_1][$atom_2] = 1;
	    $adj [$atom_2][$atom_1] = 1;
	    printf "%4d %4d  %8.4f \n",
	    $atom_1,   $atom_2,  $distance[$atom_1][$atom_2];
	    $no_bonds ++;
	} else {
	    $adj [$atom_1][$atom_2] = 0; 
	    $adj [$atom_2][$atom_1] = 0; 
	}
    }
}
printf "\n\n";
print  "no atoms: ", $max_atom+1, "\n"; 
print  "no bonds: $no_bonds \n"; 
printf "\n\n";

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
@cyclos= ();
for $atom_1 (0 .. $max_atom ) {
    $cyclops [ $atom_1 ] = 0;
    $visited[ $atom_1 ] = 0;
}

@path = ();
%found = ();
dfs (0, -1);


for $atom_1 (0 .. $max_atom ) {
    print "$atom_1   $cyclops[$atom_1] \n";
}





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
