#! /usr/bin/perl -w
# read in PDB file and a seqeunce
# delete all the sidechains, keeping Cbravo's only
# where possible and appropriate, and replace the name by the name from the 
# sequence

use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined $ARGV[0] ) ||
    die "Usage: pdb2seq.pl  <pdbfile>.\n";
$pdbfile =  $ARGV[0];


$filename = $pdbfile;

open ( IF, "<$filename" ) || die "Cno $filename: $!.\n";

$old_res_seq = -100;
$old_res_name  ="";
$res_ctr = 0;
while ( <IF> ) {

    if ( ! /^ATOM/ && !/^HETATM/ ) {
	next;
    }

    $res_seq  = substr $_, 22, 5;  $res_seq=~ s/\s//g;
    $res_name = substr $_,  17, 4; $res_name=~ s/\s//g;


    if ( $res_seq ne $old_res_seq  ||  ! ($res_name eq $old_res_name) ){
	$old_res_seq =  $res_seq;
	$old_res_name =  $res_name;
	$res_ctr++;
    }
}
$peptide_length = $res_ctr;

seek IF, 0, 0; # rewind

$old_res_seq = -100;
$old_res_name  ="";
$res_ctr = 0;
while ( <IF> ) {

    if ( ! /^ATOM/ && !/^HETATM/ ) {
	next;
    }

    $res_seq  = substr $_, 22, 5;  $res_seq=~ s/\s//g;
    $res_name = substr $_,  17, 4; $res_name=~ s/\s//g;


    if ( $res_seq ne $old_res_seq  ||  ! ($res_name eq $old_res_name) ){
	$res_ctr++;
	if (  $res_name eq "LYS" ) {
	    $new_res_name = "LYP";
	} elsif  (  $res_name eq "CYS" ) {
	     $new_res_name = "CYN";
	} else {
	    $new_res_name = $res_name;
	}
	if ( $res_ctr==1 ) {
	    $new_res_name = "N".$new_res_name;
	} elsif ( $res_ctr== $peptide_length) {
	    $new_res_name = "C".$new_res_name;
	}
	print "$res_name     $new_res_name \n";
	$old_res_seq =  $res_seq;
	$old_res_name =  $res_name;
    }
}




close IF;

