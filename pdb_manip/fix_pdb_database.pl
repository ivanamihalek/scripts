#! /usr/bin/perl -w


# add dssp generated header for the files whic do not have it

$in_pdb_dir = "/home/ivanam/databases/pdbfiles";

#$in_pdb_names = "/home/ivanam/databases/pdb_seqres/pdb_chains";
$in_pdb_names = "tmp.chains";
open (IF, "<$in_pdb_names") ||
    die "Cno $in_pdb_names: $!\n";

$out_pdb_dir = "/home/ivanam/databases/pdb_dssp_fixed";

$dssp = "/home/ivanam/downloads/dssp";
$dssp2pdb = "/home/ivanam/downloads/dssp2pdb";

$pdbdown = "/home/ivanam/perlscr/downloading/pdbdownload.pl";

($name, $chain) = ();

$ctr = 0;
while ( <IF> ) {
    chomp;
    ($name, $chain) = split;
    $ctr ++;
    ( ! ($ctr%100) ) && print "$name $ctr\n";
    
    next if (defined $already_checked{$name});
    $already_checked{$name} = 1;
    $infile = "$in_pdb_dir/$name.pdb";
    if ( ! -e $infile ) {
	printf "\t downloading  $name $ctr\n";
	`$pdbdown $name`;
    }
    $helix_ret  = "" || `awk \'\$1==\"HELIX\"\' $infile`;
    $strand_ret = "" ||  `awk \'\$1==\"SHEET\"\' $infile`;
    if ( !$helix_ret  && !$strand_ret) {
	print "$name\n";
	next if ( -e "$out_pdb_dir/$name.pdb" );
	$cmd = "$dssp  $infile > tmp.dssp";
	system $cmd;
	$cmd = "$dssp2pdb  tmp.dssp  $infile > $out_pdb_dir/$name.pdb";
	system $cmd;
        `rm tmp.dssp`;
    }
}

close IF;
