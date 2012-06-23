#! /usr/bin/perl -w
# find box around set of PDB coords - for docking

use IO::Handle;         #autoflush
# FH -> autoflush(1);


(defined $ARGV[0]   ) ||
    die "usage: dlg_monitor.pl   <dlgfile> [-m <macromolecule>] [-orig <original ligand pose>].\n";

$dlg =  $ARGV[0];
$macm = "";
$original = "";
for  $i (1,3) {
    if ( defined  $ARGV[$i]) {
	if ( $ARGV[$i] =~ "-m" ) {
	    $macm =  $ARGV[$i+1];
	} elsif ( $ARGV[$i] =~ "-orig" ) {
	    $original =  $ARGV[$i+1];
	}
    }
}
if ( $original ) {
    `/home/i/imihalek/perlscr/pdb_manip/pdb_chain_rename.pl  $original  A > tmpA.pdb`;
}


open ( DLG, "<$dlg") ||
    die "could not open $dlg.\n";

$pdb = "";
if ( $macm  ) {
    #slurp in the input as a single string
   
    open ( MAC, "<$macm") ||
	die "could not open $macm.\n";
    undef $/;
    $pdb = <MAC>;
    $/ = "\n";
}

$dir = "docked_pdb" ;
if ( ! -e $dir ) {
    mkdir $dir ||
	die "Could not make $dir directory\n";
}


$ctr = 0;
$new_pdb = "";
 while ( <DLG> ) {
    next  if ( !/^DOCKED/);
    next  if ( ! ( /USER/ || /ATOM/ || /TER/) );

    if ( /Final Docked Energy/ ) {
	$ctr ++;
	@aux = split;
	printf "  %15s %5d ",$aux[$#aux-2], $ctr ;
	$new_pdb  = $pdb;
    }
    if (  /ATOM/ ) {
	$tmp = $_;
	$tmp =~ s/DOCKED\: //;
	$new_pdb .= $tmp;
    } 
    if ( /TER/ ) {
	$outname = "$dir/docked_config.$ctr.pdb";
	open (OF, ">$outname" ) ||
	    die "Cno open  $outname: $!.\n";
	print OF $new_pdb;
	close OF;
	if ($original ) {
	    $ret = `rmsd.pl $dir/docked_config.$ctr.pdb $original`; chomp $ret;
	    print " $ret  ";
	    `/home/i/imihalek/perlscr/pdb_manip/pdb_chain_rename.pl  $dir/docked_config.$ctr.pdb B > tmpB.pdb`;
	    `cat tmpA.pdb tmpB.pdb >  $dir/docked_config.$ctr.pdb`;
	    
	    
	}
	print "\n";
	$new_pdb = "";
    } 
}

for $file ( "tmpA.pdb", "tmpB.pdb") {
    ( -e $file) && `rm $file`;
}
