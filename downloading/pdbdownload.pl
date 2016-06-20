#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
# Ivana, Dec 2001
# make pdbfiles directory  and download the pdbfiles
# for proteins with names piped in

defined ( $ARGV[0] ) ||
    die "Usage: pdbdownload.pl <pdbname>.\n";

@pdbnames = ();
if ( -e $ARGV[0]  ) {
    @pdbnames = split "\n", `cat $ARGV[0]`;

} else {
    push @pdbnames, $ARGV[0];
}


use Net::FTP;

$PDB_REPOSITORY = "/mnt/databases/pdb";

(-e $PDB_REPOSITORY) || ($PDB_REPOSITORY = "/Users/ivana/databases/pdbfiles");
(-e $PDB_REPOSITORY) || die "pdb repository not found.\n";


foreach $pdbname (@pdbnames) {

    $pdbname =~ s/\s//g;
    @aux  = split ('\.', $pdbname); # get rid of extension
    $pdbname =  lc substr ($aux[0], 0, 4);
    if (  -e "$PDB_REPOSITORY/$pdbname.pdb" ) {
	print "$pdbname.pdb found in $PDB_REPOSITORY\n";
	next;
    }
    print $pdbname, " \n"; 
    
    $ftp = Net::FTP->new("ftp.wwpdb.org", Debug => 0, Passive=> 1)
	or die "Cannot connect to ftp.wwpdb.org: $@";

    $ftp->login("anonymous",'-anonymous@')
	or die "Cannot login ", $ftp->message;

    $ftp->cwd("/pub/pdb/data/structures/all/pdb")
	or die "Cannot change working directory ", $ftp->message;
    $ftp->binary;
    $ftp->get("pdb$pdbname.ent.gz")
        or die "get failed ", $ftp->message;

    system ( "gunzip pdb$pdbname.ent.gz" ) && 
	die "error uncompressing pdb$pdbname.ent.gz.\n";
	
    `mv  pdb$pdbname.ent $PDB_REPOSITORY/$pdbname.pdb`;

    print "\t downloaded to $PDB_REPOSITORY \n"; 
}
