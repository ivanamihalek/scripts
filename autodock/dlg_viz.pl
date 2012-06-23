#! /usr/bin/perl -w
# find box around set of PDB coords - for docking

use IO::Handle;         #autoflush
# FH -> autoflush(1);

sub cluster_rep_output ();

$tanimoto = "/home/i/imihalek/c-utils/tanimoto/tanimoto";

( -e $tanimoto) || die "$tanimoto not found.\n";

if ( ! defined $ARGV[0]  ) {
    print  "usage: dlg_viz.pl   <dlg name> [<reference structure>] [<protein pdb>] [<ranks file>]\n."; 
    exit;
}

$dlg =  $ARGV[0];

$ref = "";
if ( defined $ARGV[1] ) {
    $ref =  $ARGV[1];
}

$protein_struct = "";
if ( defined $ARGV[2] ) {
    $protein_struct =  $ARGV[2];
}

$ranksfile = "";
if ( defined $ARGV[3] ) {
    $ranksfile=  $ARGV[3];
}


open ( DLG, "<$dlg") ||
    die "could not open $dlg.\n";


$dir = "docked_pdb" ;
if ( ! -e $dir ) {
    mkdir $dir ||
	die "Could not make $dir directory\n";
}

# score the native config
if ( $ref ) {
    $rank = 0;
    $min_energy = 0.0;

    #slurp in the input as a single string
    open ( FH, "<$ref" ) ||
	die "Cno $ref: $!. \n";
    undef $/;
    $new_pdb = <FH>;
    $/ = "\n";
    close FH;

    cluster_rep_output ();
}



$rank = -1;
$reading = 0;
$new_pdb = "";
$ctr = 0;
while ( <DLG> ) {
    last if ( /CLUSTER ANALYSIS OF CONFORMATIONS/);
}
while ( <DLG> ) {
   # next  if ( !/\S/);
    next  if ( ! ( /^USER/ || /^ATOM/ || /^TER/) );

    if ( /Cluster Rank = (\d+)/ && $rank != $1)  { #new rank
	cluster_rep_output ();
	$rank = $1;
	$min_energy = 10e5;
	$new_pdb = "";
    }

    if ( /Final Docked Energy/ ) {
	$ctr ++;
	@aux = split;
	$energy =  $aux[$#aux-2];

	if ( $energy < $min_energy) {
	    $min_energy = $energy;
	    $reading = 1;
	    $new_pdb = "";
	}
	#printf "energy  %s %s,    ", @aux[$#aux-2 ..$#aux-1];
    }

    if (  /^ATOM/ && $reading) {
	(substr $_, 21 , 1) = "L";
	$new_pdb .= $_;
    } 

    if ( /^TER/  && $reading ) {	
	$reading = 0;
    } 
}

cluster_rep_output ();

sub cluster_rep_output () {	


    if ( !  $new_pdb) {
	return;
    }

    #output to file  
    $outname = "$dir/docked_config.$rank.pdb";
    if ( ! -e $outname ) {
	open (OF, ">$outname" ) ||
	    die "Cno open  $outname: $!.\n";

	print OF "MODEL\n";
	print OF $new_pdb;
	print OF "ENDMDL\n";
	close OF;
    }

    #diagnostic output to stdout
    print " cluster of solutions:   rank $rank     ";
    print " min_energy $min_energy kcal/mol       ";
    if ( $ref ) { # if reference structure given. calculate rmsd
	$ret = `rmsd.pl  $ref  $outname`;
	$ret =~ /(\S+)/;
	$rmsd = $1;
	printf "rmsd $rmsd     " ;
	$ret = `$tanimoto $ref  $outname | grep tanimoto`;
	chomp $ret;
	@aux = split " ", $ret;
	$tan = pop @aux;
	printf "tanimoto $tan     " ;
	if (  $protein_struct && $ranksfile) {
	    #$ranksfile =  $mm_path."/$name"."/$name".".pruned.ranks";
	    $ret = `score_ligand_position.pl $protein_struct  $outname $ranksfile`;
	   
	    @aux = split " ", $ret;
	    $score1 = $aux[0];
	    $score2 = $aux[4];
	    printf "score1  %8.3f    score2  % 8.3f " , $score1, $score2;
	}
    }
    printf "\n" ;


}
