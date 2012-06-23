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


$res_ctr = 0;
$old_res_seq = -100;
$old_res_name  ="";
$filename = $pdbfile;

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

    next if ( $alt_loc =~ "B" );
    $newline = $_;
    substr ($newline,16, 1 ) = " "; # alt loc

    if ( $res_seq ne $old_res_seq  ||  ! ($res_name eq $old_res_name) ){
	$old_res_seq =  $res_seq;
	$old_res_name =  $res_name;
	$res_ctr++;
    }
}
close IF;
print "$res_ctr\n";
