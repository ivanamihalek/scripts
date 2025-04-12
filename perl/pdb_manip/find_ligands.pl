#!/usr/bin/perl -w  
$PDBFILES = "pdbfiles"; 
$PDBNAMES_FILE = "pdbnames"; 

open (PDBNAMES,"<$PDBNAMES_FILE" ) ||
    die "Could not open $PDBNAMES_FILE\n";
$geom = "/home/i/imihalek/perlscr/pdb_manip/geom_epitope.pl";

while (<PDBNAMES>) {
    chomp;
    @files = split ;
    
    foreach $filename ( @files ){
	# make sure I have the .pdb extension:
	@aux  = split ('\.', $filename);
	if ( $aux [$#aux] !~ /pdb/ ) {
	    $filename = (uc $filename).".pdb";
	}
	if ( ! open ( INFILE, "<$PDBFILES/$filename") ) {
	     $filename = lc $filename;
	     open ( INFILE, "<$PDBFILES/$filename") ||
		    die "cannot open $PDBFILES/$filename file \n" ;
	 }
	print "\n*******************************************\n" ;
	print "* processing $filename \n" ;
	print "*******************************************\n" ;

	$pdbname = substr $filename, 0, 4;
	$dir = $pdbname."_ligands";
	(  -e $dir ) || `mkdir $dir`;

	$old_chain_id = "";
	$chain_ctr = -1;
        while ( <INFILE> ) {
	    if  ( /^HETATM/ && !/HOH/ ) {
		$chain_id  = substr $_, 21,1;
		if ( $chain_id  ne $old_chain_id ) {
		    $old_chain_id = $chain_id;
		    $chain_ctr++;
		    $ligand[$chain_ctr] = $_;
		    $ligand_id[$chain_ctr] = $chain_id;
		}
		$ligand[$chain_ctr] .= $_;
	    }
	    if ( /ATOM/ &&  (substr $_, 17, 2) !~ /\w/ ) {
		$chain_id = substr $_, 21,1;
		if ( $chain_id ne $old_chain_id ) {
		    $old_chain_id = $chain_id;
		    $chain_ctr++;
		    $dna[$chain_ctr] = $_;
		    $dna_id[$chain_ctr] = $chain_id;
		}
		$dna[$chain_ctr] .= $_;
	    }
	}
	$no_ligands = $#ligand +1;
	$no_dnas = $#dna + 1;

	#####################################################
	# ligand processing & output
	#####################################################
	print "found $no_ligands ligands\n";
	for ($ctr=0; $ctr<$no_ligands; $ctr++ ) {
	    $outfile = "$dir/$pdbname".$ligand_id[$ctr].".pdb";
	    open (OF, ">$outfile") || die "Cno $outfile: $!.\n";
	    print OF $ligand[$ctr];
	    close OF; 
	    print "\t  $ligand_id[$ctr]\n";
	} 
	#####################################################
	# dna  processing & output - complicated by each strand
	#                            carrying different id
	#####################################################
	for ($ctr=0; $ctr<$no_dnas; $ctr++ ) {
	    $outfile = "$dir/$pdbname".$dna_id[$ctr].".pdb";
	    open (OF, ">$outfile") || die "Cno $outfile: $!.\n";
	    print OF $dna[$ctr];
	    close OF; 
	} 
	$no_pairs = 0;
	@compl_name = ();
	for ($ctr=0; $ctr<$no_dnas-1; $ctr++ ) {
	    next if ( defined $pair{$ctr} );
	    $outfile = "$dir/$pdbname".$dna_id[$ctr].".pdb";
	    for ($ctr2=$ctr+1; $ctr2<$no_dnas; $ctr2++ ) {
		next if ( defined    $pair{$ctr2} );
		$outfile2 = "$dir/$pdbname".$dna_id[$ctr2].".pdb";	
		$ret = "" || `$geom $outfile $outfile2`; # see if they are in contact - one day this test should be improved
		if ( $ret ) {
		    #print "taking that $dna_id[$ctr] and $dna_id[$ctr2] are complementary.\n";
		    $pair{$ctr}  = $ctr2;
		    $pair{$ctr2} = $ctr;
		    $outfile3 =  "$dir/$pdbname".$dna_id[$ctr].$dna_id[$ctr2].".pdb";
		    `cat $outfile $outfile2 > $outfile3`; 
		    `rm  $outfile $outfile2`;
		    $no_pairs ++;
		    push @compl_name, $dna_id[$ctr].$dna_id[$ctr2];
		} 
	    } 
	} 
	if ( $no_pairs) {
	    $plural = "";  ($no_pairs > 1) && ($plural = "s");
	    print "found $no_pairs pair$plural of dna strands\n";
	    foreach $name (@compl_name ) {
		print "\t $name\n";
	    }
	} else {
	    $plural = "";  ($no_dnas > 1) && ($plural = "s");
	    print "found $no_dnas individual dna strand$plural\n";
	    for ($ctr=0; $ctr<$no_dnas; $ctr++ ) {
		print "\t  $dna_id[$ctr]\n";
	    } 
	}
	
    } 
}
