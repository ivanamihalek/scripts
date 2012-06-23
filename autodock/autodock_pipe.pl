#! /usr/bin/perl -w
use strict;     
###############################################################
(defined $ARGV[1] ) ||
    die "Usage: autodock_pipe.pl  <target.pdb>  <ligand.pdb>.\n";

my ($target, $ligand) = @ARGV;
my $file;
foreach $file ($target, $ligand) {
    ( -e $file) ||
	die "$file not found.\n";
}

sub find_stem ( @);
my ($target_stem, $ligand_stem);
$target_stem = find_stem ($target);
$ligand_stem = find_stem ($ligand);


###############################################################
my $prodrg = "/home/i/imihalek/downloads/prodrg/prodrg";
my $protonate = "/home/neem/autodock/dist305/src/protonate/protonate";
my $proton_info = "/home/neem/autodock/dist305/src/protonate/PROTON_INFO.kollua_polH";
my $partial = "/home/i/imihalek/perlscr/autodock/partial_charges.pl";
my $addsol = "/home/neem/autodock/dist305/src/addsol/addsol";
my $autodock = "/home/neem/autodock/dist305/src/autodock/autodock3";
my $autogrid = "/home/neem/autodock/dist305/src/autogrid/autogrid3";
my $autodock_scripts_path = "/home/i/imihalek/perlscr/autodock";
my $prepare_pf = "$autodock_scripts_path/prepare_param_files.sh";
my $pdb_center = "/home/i/imihalek/perlscr/pdb_manip/geom_center.pl";

foreach $file ( $prodrg,  $protonate, $proton_info, $partial, $addsol,
	$autodock, $autogrid, $autodock_scripts_path, $prepare_pf, $pdb_center) {
    ( -e $file) ||
	die "$file not found.\n";
}

$autodock = "nice  ".$autodock;
$autogrid = "nice  ".$autogrid;

##############################################################
#  prepare the ligand:
#############################################################
my $cmd;
my $ligand_pdbq = $ligand_stem.".pdbq";
if ( ! -e $ligand_pdbq  ) {
    printf "\t making $ligand_pdbq \n";
    `mkdir tmp_prodrg`;
    chdir "tmp_prodrg";
    $cmd = "$prodrg  ../$ligand  $prodrg.param CGRP ";
    (system $cmd) && die "Error running $cmd\n";
    `mv DRGAD3.PDBQ ../$ligand_pdbq`; # DRGAD3 has A for aromatic carbons
    chdir "..";
    `rm -rf tmp_prodrg`;
} else {
    printf "\t $ligand_pdbq found\n";
}

##############################################################
#  prepare big molecule
#############################################################
my $target_pdbqs = $target_stem.".pdbqs";
if ( ! -e  $target_pdbqs  ) {
    # protonate
    printf "\t protonating  $target\n";
    ( -e "PROTON_INFO" ) || `ln -s $proton_info PROTON_INFO`;
    $cmd = "$protonate < $target > tmp.H.pdb";
    (system $cmd) && die "Error running $cmd\n";
    # add charges
    printf "\t adding charges to   $target\n";
    $cmd = "$partial  tmp.H ";
    (system $cmd) && die "Error running $cmd\n";
    # add solvation parameters
    printf "\t adding solvation parameters $target\n";
    $cmd = "$addsol tmp.H.pdbq  $target_pdbqs";
    (system $cmd) && die "Error running $cmd\n";
    `rm  tmp.H.pdb  tmp.H.pdbq`;
} else {
    printf "\t $target_pdbqs found\n";
}


##############################################################
#  prepare grid and docking  parameter files
#############################################################
my ( $gpf, $dpf, $ret);
$gpf = "$target_stem.gpf";
$dpf = "$ligand_stem.$target_stem.dpf";
if ( ! -e $gpf || ! -e $dpf ) {
    printf "\t preparing dpf and gpf files\n";
    $cmd = "$prepare_pf  $ligand_pdbq $target_pdbqs  $autodock_scripts_path";
    (system $cmd) && die "Error running $cmd\n";
    # "fix" the grid center
    if ( -e "grid_center" ) {
	$ret = `cat grid_center`; chomp $ret;
	printf "\t grid_center found: $ret\n";
    } else {
	$ret = `$pdb_center $ligand`; chomp $ret; 
	printf "\t grid_center not  found; using $ret\n"; 
    } 
    `sed \'s/<xc> <yc> <zc>/$ret/\' gpf.tmp > $gpf`;
    `rm  gpf.tmp`;
} else { 
    printf "\t $gpf and $dpf found\n"; 
}
 


##############################################################
#  run autogridgrid 
#############################################################
if ( ! -e   "$target_stem.glg" ) {
    printf "\t running autogrid\n";
    $cmd = "$autogrid -p $gpf -l  $target_stem.glg";
    (system $cmd) && die "Error running $cmd\n";
} else {
    printf "\t $target_stem.glg found - I am assuming this means autogrid OK\n";
}


##############################################################
#  run autodock
#############################################################
printf "\t running autodock\n";
$cmd = "$autodock -p $dpf -l  $ligand_stem.dlg";
(system $cmd) && die "Error running $cmd\n";


##############################################################
#  re-evaluate the pose using gromacs g_lie utility
#############################################################
sub find_stem ( @ ) {
    my $path = $_[0];
    my @aux;
    my $stem;
    @aux = split '\/', $path;

    $stem = pop @aux;
    @aux = split '\.', $stem;
    pop @aux;
    $stem = join '.', @aux;

    return $stem;
}
