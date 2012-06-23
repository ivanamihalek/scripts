

########################################################################################################## 
sub make_rasmol_if ( @ ) {

    my $name = $_[0]; 
    shift @_;
    my $interface = ""; 
    foreach $residue ( @_ )  {
	$interface .= "_$residue";
    }
    $interface .= "_"; 

    # link the pdb here so rasmol does not use the path (might end up too long, adn in the
    # the package for the user there better be no paths
    ( -e "$pdbname.pdb" ) || `ln -s  $home/pdbfiles/$pdbname.pdb $pdbname.pdb`;

    # make rasmol script and ps 
    $psfile = "$chain.$name.if.ps";
    if (  modification_time ( "$home/texfiles/$psfile" ) < modification_time ("$chain.ranks_sorted") ) {

	$rsfile = "$chain.$name.if.rs"; 

	# determine which file contains the ligand
	$structure_file = "";
	if ( " @dnas " =~ $name ) {
	    $aux = $name;
	    $chain_name_1 = chop $aux;
	    $chain_name_2 = chop $aux;
	    $instructions = "\n restrict :$chain_name\nselect :$chain_name_1, :$chain_name_2\n spacefill off\n backbone 250\n color green\n";
	    $structure_file = "$home/$pdbname/$pdbname"."_dna/$name.pdb"; 
	} elsif ( " @rnas " =~ $name ) {
	    $aux = $name;
	    $chain_name_1 = chop $aux;
	    $instructions = "\n restrict :$chain_name\n select :$chain_name_1\n spacefill off\n backbone 150\n color green\n";
	    #in this particular case replace interface with coords of the ligand - in hope that it will becoma visible
            # + need to replace using name with using pdb_id - this sometimes does not work
	    $structure_file = "$home/$pdbname/$pdbname"."_rna/$pdbname.$name.pdb"; 
	} elsif ( defined $hetname{$name} ) {
	    if ( $chain_associated {$name} ) {
		$aux = $name;
		chop $aux;
		$selection = "$aux:$chain_name";
	    } else {
		$selection = $name;
	    }
	    $instructions = "\n restrict :$chain_name\n select $selection\n spacefill \n color green\n";
	    $structure_file = "$home/$pdbname/$pdbname"."_ligands/$pdbname.$name.pdb"; 
	} else {
	    $chain_name   = $chain_names{$name};
	    $instructions = "\nselect :$chain_name\n spacefill off\n backbone 150\n";
	    if ( " @chains " =~ $name ) {
		$structure_file = "$home/$pdbname/$name/$name.pdb"; 
	    } else {
		foreach $chain2 ( @chains ) {
		    if ( " @{$identical_chains{$chain2}} " =~ $name ) {
			$structure_file = "$home/$pdbname/$chain2"."_identical_chains/$name.pdb"; 
		    }		    
		}
	    }
	}
	( $structure_file ) || die "Structure file not determined in make_rasmol_if.\n";

	# find geom center of the ligand
	$command = $path{"geom_center"}." $structure_file ";  
	($x_center, $y_center, $z_center,) = split " ", `$command`;
	# orient pdb so that we look at that point face-on
	$command = $path{"pdb_point_place"}."  $pdbname.pdb  $x_center  $y_center  $z_center  > tmp.pdb"; 
	(system `$command`) || die "Failure rotating $pdbname.pdb.\n";

	# use cbcvg here
	$chain_name = $chain_names{$chain};
	$commandline = $path{"color_by_coverage"}."  $chain.ranks_sorted  tmp.pdb  $rsfile $chain_name";
	print "$commandline \n";
	( system $commandline) &&  die "cbcvg failure.\n";


	open (OF,">>$rsfile") || die "Cno $rsfile for append: $!.\n";
	print OF $instructions;
	close OF;
	
	# find geom center of the ligand
	$command = $path{"geom_center"}." $structure_file ";  
	($x_center, $y_center, $z_center,) = split " ", `$command`;
	# orient pdb so that we look at that point face-on
	$rasmol = "";
	# slab passing through the center of the ligand
	$command = $path{"slab"}."   $pdbname.pdb   $x_center   $y_center  $z_center  ";  
	$slab_position = `$command`; chomp $slab_position;
	$rasmol .= "slab $slab_position\n";


	open (OF, ">>$rsfile" ) || die "Cno $rsfile.\n";
	print OF  $rasmol; 
	close OF; 
 

	# make postscript 
	$instructions  = "write ps \"$psfile\"\n";
	$instructions .= "quit\n";
	open (OF, ">tmp" ) || die "Cno tmp: $!.\n";
	print OF $instructions;
	close OF;
	$commandline = $path{"rasmol"}." -script $rsfile < tmp > /dev/null ";
	( system $commandline) &&  die "rasmol failure.\n";
	`mv $psfile  $home/texfiles`;
	( -e "tmp" ) && (`rm tmp`); 
    }
}



