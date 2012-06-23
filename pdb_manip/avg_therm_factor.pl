#! /usr/bin/perl -w
# read in PDB file and a seqeunce
# delete all the sidechains, keeping Cbravo's only
# where possible and appropriate, and replace the name by the name from the 
# sequence

use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined $ARGV[0] ) ||
    die "Usage: avg_therm_factor.pl  <pdbfile>.\n";
$pdbfile =  $ARGV[0];


$old_res_seq = -100;
$old_res_name  ="";
$filename = $pdbfile;

$avg_thm_fact = 0;
$nr_residue_atoms = 0;

open ( IF, "<$filename" ) || die "Cno $filename: $!.\n";
while ( <IF> ) {

    if ( ! /^ATOM/ && !/^HETATM/ ) {
	next;
    }

    $name = substr $_,  12, 4 ;  $name =~ s/\s//g; 
    $name =~ s/\*//g; 
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_seq  = substr $_, 22, 5;  $res_seq=~ s/\s//g;
    $res_name = substr $_,  17, 4; $res_name=~ s/\s//g;
    $thm_fact = substr $_,  60, 6; $thm_fact=~ s/\s//g;

    next if (  $res_name eq "HOH");
    next if ( $alt_loc =~ "B" );

    $avg_thm_fact += $thm_fact;
    $nr_residue_atoms++;

    if ( $res_seq ne $old_res_seq ){
	if ( $old_res_name ) {
	    $avg_thm_fact /= $nr_residue_atoms;
	    printf "%5d   %4s  %6.2f\n", $old_res_seq,  $old_res_name, $avg_thm_fact;
	}
	$old_res_seq =  $res_seq;
	$old_res_name =  $res_name;
	$avg_thm_fact = 0;
	$nr_residue_atoms = 0;
    }
}

$avg_thm_fact /= $nr_residue_atoms;
printf "%5d   %4s  %6.2f\n", $old_res_seq,  $old_res_name, $avg_thm_fact;



close IF;
print "\n";
