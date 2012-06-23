#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
# Ivana, Dec 2001
# make pdbfiles directory  and download the pdbfiles
# for proteins with names piped in


use Net::FTP;

$PDB_REPOSITORY = "/home/pine/pdbfiles";
$PDBDIR =  "pdbfiles";
$PDBNAMESFILE = "pdbnames";

if ( ! -e "$PDBDIR") {
    mkdir ("$PDBDIR", 0770) ||
	die "Cannot make $PDBDIR directory .\n";
}

open (PDBNAMES,"<$PDBNAMESFILE" ) ||
    die "Could not open $PDBNAMESFILE\n";

while ( <PDBNAMES>) {
    chomp;
    @pdbnames = split;
    foreach $pdbname ( @pdbnames ){
	@aux  = split ('\.', $pdbname); # get rid of extension
	$pdbname =  lc substr ($aux[0], 0, 4);
	if ( -e "$PDBDIR/$pdbname.pdb" ) {
	    print "$pdbname.pdb found in $PDBDIR\n";
	    next;
	}
	if (  -e "$PDB_REPOSITORY/$pdbname.pdb" ) {
	    print "$pdbname.pdb found in $PDB_REPOSITORY\n";
	    `ln -s $PDB_REPOSITORY/$pdbname.pdb $PDBDIR`;
	    next;
	}
	print $pdbname, " \n"; 

	$ftp = Net::FTP->new("ftp.rcsb.org", Debug => 0)
	    or die "Cannot connect to ftp.rcsb.org: $@";

	$ftp->login("anonymous",'-anonymous@')
	    or die "Cannot login ", $ftp->message;

	$ftp->cwd("/pub/pdb/data/structures/all/pdb")
	    or die "Cannot change working directory ", $ftp->message;

	$ftp->get("pdb$pdbname.ent.Z");

	system ( "uncompress pdb$pdbname.ent.Z" ) && 
	    die "error uncompressing pdb$pdbname.ent.Z.\n";
	
	`mv  pdb$pdbname.ent $PDBDIR/$pdbname.pdb`;

	    
	    
     }
			
}

close PDBNAMES;
