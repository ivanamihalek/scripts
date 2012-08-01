#!/usr/bin/perl -w  

( defined $ARGV[0] ) || die "Usage: pdbparse.pl  <pdbnames_file>.\n";


$pdbnames_file = $ARGV[0];  
$PDBFILES = "pdbfiles"; 

( -e $PDBFILES) || die "$PDBFILES directory not found.";

open (PDBNAMES,"<$pdbnames_file" ) ||
    die "Could not open $pdbnames_file";

$geom_epitope = "/home/i/imihalek/c-utils/geom_epitope";
( -e $geom_epitope) || die "Could not find $geom_epitope.";
$affine = "/home/i/imihalek/perlscr/pdb_manip/pdb_affine_tfm.pl";
( -e $affine) || die "Could not find $affine.";


%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
		'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
		'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
                'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E'); 
#sub printseq();
sub process_coord_entry (); 
sub process_affine_tfmd (@);
sub print_seq (@); 
sub dna_pairs ();
sub trivial_biomt();
sub trivial_tfm(@);
#sub dye (@);

$home = `pwd`;
chomp $home;
 
#(-e "$home/successes" ) && `rm $home/successes`;
#(-e "$home/failures" )  && `rm $home/failures`;

@terminal_modifications = ("ACE", "PCA", "DIP", "NH2");

TOP:
while (<PDBNAMES>) { 
    chomp;
    
    @files = split ;
    
    foreach $file_name ( @files ){
	chdir $home;

	# big cleanup
	$reading_chain = 0;
	$biomt_ctr = 0;
	$symm_ctr  = 0;
	$title = "";
	$source = "";
	$exp = "";
	$compound= "";
	$biomt_applies_to = "";

	@biomt = (); @biomt_applies_to = ();@biomt_chains = ();
	@chain_ids = ();
	@pairs = ();
	@site = ();
	@symmetry = ();

	%chain_related = ();
	%chem_name  = ();
	%coord = ();
	%coord_seq = ();
	%dna = ();
	%full_chain_3 = ();
	%hbond_ctr  = ();
	%hetnam_translation = ();
	%hetero_coord = ();
	%original = ();
	%synonym  = ();
	%ssbond   = ();
	%sltbrg_ctr = ();

	# make sure I have the .pdb extension:
	@aux  = split ('\.', $file_name);
	$name = $aux[0];
	if ( $aux [$#aux] !~ /pdb/ ) {
	    $file_name = (uc $file_name).".pdb";
	}
	if ( ! open ( INFILE, "<$PDBFILES/$file_name") ) {
	     $file_name = lc $file_name;
	     open ( INFILE, "<$PDBFILES/$file_name") ||
		    die "cannot open $PDBFILES/$file_name file." ;
	 }
	print "\n*******************************************\n" ;
	print "* reading $file_name \n" ;
	print "*******************************************\n" ;
	( -e $name ) || `mkdir $name`;
	chdir $name;

	while ( <INFILE> ) {
	    #print "$. $letter_code{'PRO'}\n";
	    next if ( ! /\S/ );
	    # check for nonprintable characters:
	    $record_name = substr $_, 0, 6;
	    if ( length $_ > 6 ) {
		$continuation = substr $_, 8, 2;  $continuation  =~ s/\s//g;
	    } else {
		$continuation = "";
	    }
	    $ser_num = $continuation; # same columns, different field
	    if ( $record_name =~  /^HEADER/ ) {
		$pdbname = lc substr $_, 62, 4;
		#$pdb_date = substr $_, 50, 9;
	    } elsif ( $record_name =~  /^TITLE/) {
		$cont = ($continuation && $continuation>1) ;
		($cont) ||  ($title  =  substr $_, 10, 60);
		($cont) &&  ($title .=  substr $_, 10, 60);
	    } elsif ( $record_name =~  /^COMPND/) {
		$cont = ($continuation && $continuation>1) ;
		($cont) ||  ($compound  =  substr $_, 10);
		($cont) &&  ($compound .=  substr $_, 10);
	    } elsif ( $record_name =~  /^SOURCE/) {
		( /ORGANISM_SCIENTIFIC\:([\w\s]+).*\n/ ) &&  ($source = $1);
	    } elsif ( $record_name =~  /^KEYWDS/) {
	    } elsif ( $record_name =~  /^EXPDTA/) {
		$cont = ($continuation && $continuation>1) ;
		($cont) ||  ($exp  =  substr $_, 10, 60);
		($cont) &&  ($exp .=  substr $_, 10, 60);
	    } elsif ( $record_name =~  /^REMARK/) {
		#generate biomolecule
		$remark_num = substr $_, 7, 3;
	        if ($remark_num == 350  ) { # remark 350 -- BIOMT
		    (substr ($_, 11,59 ) !~ /\S/  ) && (@biomt_applies_to = ());
		    if ( /APPLY / ) {
			chomp;
			@aux  = split '\:';
			$aux2 = pop @aux;  
			$aux2 =~ s/[\s\.\,]//g;
			if ( $aux2 eq "NULL" ) {
			    push @biomt_applies_to, "";
			} else {
			    @aux  = split'', $aux2;
			    push @biomt_applies_to, @aux;
			}
		    } elsif  (/BIOMT(\d) / ) {
			$biomt_ctr  = (substr $_, 20, 3) - 1;
			if ( $1 == 1 ) {
			    $biomt[$biomt_ctr] = "";
			    if ( ! @biomt_applies_to && $biomt_ctr) { # in case one "APPLY" line refers to severla BIOMT lines
				@{$biomt_chains[$biomt_ctr]} = @{$biomt_chains[$biomt_ctr-1]};
			    } else {
				@{$biomt_chains[$biomt_ctr]}= @biomt_applies_to;
			    }
			    @biomt_applies_to = ();
			}
			$biomt[$biomt_ctr] .=  substr $_, 23;
		    }
		} elsif ( $remark_num == 290 ) { # remark 290 -- SMTRY
		    if ( /SMTRY(\d)/ ) { 
			$symm_ctr  = (substr $_, 20, 3) - 1;
			( $1 == 1 )  &&  ($symmetry[$symm_ctr] = "");
			$symmetry[$symm_ctr] .=  substr $_, 23;
		    }
		}
		
	    } elsif ( $record_name =~  /^SEQRES/) {
		$chain_id = substr $_, 11, 1;  $chain_id =~ s/\s//g;
		( $ser_num == 1) && ( $full_chain_3{$chain_id} = "");
		$res_name = substr $_, 19, 3;  $res_name  =~ s/\s//g;
		$dna{$chain_id} =  ( (length $res_name) == 1 );
		for ( $ctr=20; $ctr<=68; $ctr+=4) {
		    last if ( $ctr+3 > length $_ );
		    $res_name = substr $_, $ctr-1, 3;
		    $full_chain_3{$chain_id} .= $res_name;
		}
	    } elsif ( $record_name =~  /^MODRES/) {
		$res_name = substr $_, 12, 3;
		$chain_id = substr $_, 16, 1; $chain_id =~ s/\s//g;
		$seq_num  = substr $_, 18, 4;
		$ins_code = substr $_, 22, 1;
		$std_name = substr $_, 24, 3;
		$descr    = substr $_, 29, 41;
		#$modification{$chain_id}{$seq_num.$ins_code} = $res_name."_".$std_name;
		if ( ! defined $letter_code{$res_name} ) {
		    ($hetnam_translation{ $res_name } = $std_name);
		    $letter_code{$res_name} = $letter_code{$std_name};
		}
	    } elsif ( $record_name =~  /^HET   /) {
		$hetnam   = substr $_, 7, 3;  $hetnam =~ s/\s//g;
		$chain_id = substr $_, 12, 1;  $chain_id =~ s/\s//g;
		$seq_num  = substr $_, 13, 4;
		$ins_code = substr $_, 18, 1;
		$descr =  substr $_, 30, 40; $descr =~ s/\s+/ /g;
		( defined  $chain_related{$hetnam}) || ($chain_related{$hetnam} = "");
		$chain_related{$hetnam} .= $chain_id;
		$chem_name{$hetnam} = $descr;

	    } elsif ( $record_name =~  /^HETNAM/   ) {
		$cont = ($continuation && $continuation>1) ;
		$hetnam   = substr $_, 11, 3; $hetnam  =~ s/\s//g;
		$descr    = substr $_, 15, 55;  $descr =~ s/\s+/ /g; 
		( $cont ) || ( $chem_name{$hetnam}  = $descr );
		( $cont ) && ( $chem_name{$hetnam} .= $descr );

	    } elsif ( $record_name =~  /^HETSYN/) {
		$cont = ($continuation && $continuation>1) ;
		$hetnam   = substr $_, 11, 3; $hetnam =~ s/\s//g;
		$descr    = substr $_, 15, 55; $descr  =~ s/\s+/ /g;
		( $cont ) || ( $synonym{$hetnam}  = $descr );
		( $cont ) && ( $synonym{$hetnam} .= $descr );

	    } elsif ( $record_name =~  /^SSBOND/) {

		$ser_num  = substr $_, 7, 3;

		#$res_name_1 = substr $_, 11,3; # this must be CYS
		$chain_id_1 = substr $_, 15, 1;  $chain_id_1 =~ s/\s//g;
		$seq_num_1  = substr $_, 17, 4;
		$ins_code_1 = substr $_, 21, 1;

		#$res_name_2 = substr $_, 25,3; # this must be CYS
		$chain_id_2 = substr $_, 29, 1;  $chain_id_2 =~ s/\s//g;
		$seq_num_2  = substr $_, 31, 4;
		$ins_code_2 = substr $_, 35, 1;

		$ssbond{$chain_id_1}{$seq_num_1.$ins_code_1} = "$chain_id_2 $seq_num_2$ins_code_2";
		$ssbond{$chain_id_2}{$seq_num_2.$ins_code_2} = "$chain_id_1 $seq_num_1$ins_code_1";
		
	    } elsif ( $record_name =~  /^HYDBND/) {

		$chain_id_1 = substr $_, 21, 1;$chain_id_1 =~ s/\s//g;
		$seq_num_1  = substr $_, 22, 4;
		$ins_code_1 = substr $_, 27, 1;

		$chain_id_2 = substr $_, 52, 1; $chain_id_2 =~ s/\s//g;
		$seq_num_2  = substr $_, 53, 4;
		$ins_code_2 = substr $_, 58, 1;

		( defined  $hbond_ctr{$chain_id_1}{$seq_num_1.$ins_code_1} ) ||
		    (  $hbond_ctr{$chain_id_1}{$seq_num_1.$ins_code_1} = 0 );
		$hbond_ctr{$chain_id_1}{$seq_num_1.$ins_code_1} ++;

		( defined  $hbond_ctr{$chain_id_2}{$seq_num_2.$ins_code_2} ) ||
		    (  $hbond_ctr{$chain_id_2}{$seq_num_2.$ins_code_2} = 0 );
		$hbond_ctr{$chain_id_2}{$seq_num_2.$ins_code_2} ++;

	    } elsif ( $record_name =~  /^SLTBRG/) {

		$chain_id_1 = substr $_, 21, 1;$chain_id_1 =~ s/\s//g;
		$seq_num_1  = substr $_, 22, 4;
		$ins_code_1 = substr $_, 26, 1;

		$chain_id_2 = substr $_, 51, 1; $chain_id_2 =~ s/\s//g;
		$seq_num_2  = substr $_, 52, 4;
		$ins_code_2 = substr $_, 56, 1;

		( defined  $sltbrg_ctr{$chain_id_1}{$seq_num_1.$ins_code_1} ) ||
		    (  $sltbrg_ctr{$chain_id_1}{$seq_num_1.$ins_code_1} = 0 );
		$sltbrg_ctr{$chain_id_1}{$seq_num_1.$ins_code_1} ++;

		( defined  $sltbrg_ctr{$chain_id_2}{$seq_num_2.$ins_code_2} ) ||
		    (  $sltbrg_ctr{$chain_id_2}{$seq_num_2.$ins_code_2} = 0 );
		$sltbrg_ctr{$chain_id_2}{$seq_num_2.$ins_code_2} ++;

	    } elsif ( $record_name =~  /^MODEL/) {
	    } elsif ( $record_name =~  /^ATOM/) {
		$reading_chain = 1;
		$chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
		$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
		$res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
		next if  (grep {$res_name eq $_ } @terminal_modifications ); # skip terminal modifications
		process_coord_entry ();


	    } elsif ( $record_name =~  /^TER/) {
		#$terminated{$chain_id} = 1;
		$reading_chain = 0;
	    } elsif ( $record_name =~  /^HETATM/) {
		$chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
		$res_seq  = substr $_, 22, 4;  $res_seq  =~ s/\s//g;
		$res_name = substr $_, 17, 3;  $res_name =~ s/\s//g;
		next if  (grep {$res_name eq $_ } @terminal_modifications ); # skip terminal modifications
		if (  $reading_chain ) { # this is modified residue
		    # replace with regular  residue name - this should be ok for trace purposes
		    ( defined $hetnam_translation{$res_name} ) ||
			die "Unknown hetero name: $res_name";
		    substr ($_, 17, 3) = $hetnam_translation{$res_name};
		    substr ($_, 0, 6) = "ATOM  ";
		    $res_name = $hetnam_translation{$res_name};
		    process_coord_entry ();
		} else { 
		    # this must be a ligand 
		    # skip if water 
		    next if ( $res_name eq "HOH" );
		    ( defined $hetero_coord{$chain_id}{$res_seq} ) ||  
			($hetero_coord{$chain_id}{$res_seq} = "");
		    $hetero_coord{$chain_id}{$res_seq} .= $_;
		    $hetero_name{$res_seq} = $res_name;
		} 
	    } elsif ( $record_name =~  /^ENDMDL/) { 
		last; # read only the first model 
	    } elsif ( $record_name =~  /^SITE/) { 
		for ( $ctr = 0; $ctr<= 22; $ctr +=11) { # threee residues in each SITE record
		    $chain_id = substr $_, 22+$ctr, 1;$chain_id =~ s/\s//g;
		    $seq_num  = substr $_, 23+$ctr, 4;$seq_num  =~ s/\s//g;
		    $ins_code = substr $_, 27+$ctr, 1;$ins_code =~ s/\s//g;
		    next if (! $seq_num );
		    push  @site, " $chain_id-$seq_num$ins_code"; # <<<----------!!!!!!!!!!!
		}
	    }  
	} 
        # output  short general info
	$filename = "general_stuff";
	open (OF, ">$filename" ) || die "Cno $filename: $!.";
	$title =~ s/\s+/ /g;
	print  OF  "title  $title \n";
	print  OF  "source $source\n";
	print  OF  "exp $exp\n";
	close OF;


	@chain_ids = keys %full_chain_3;

	# output residue descriptions for ss, saltbridge, hbon ad site records
	if (  keys %{ $ssbond{$chain_id} } || 
	      keys %{ $hbond_ctr{$chain_id} } ||
	      keys %{ $sltbrg_ctr{$chain_id} } || @site ) {
	    $filename = "pdb_annotation";
	    open (OF, ">$filename" ) || die "Cno $filename: $!.";
	    foreach $chain_id (@chain_ids ) {
		foreach $res_id( keys %{ $ssbond{$chain_id} } ) {
		    print OF  "residue: $res_id   chain: $chain_id   annotation: ss bond (PDB)\n";
		}
		foreach $res_id( keys %{ $hbond_ctr{$chain_id} } ) {
		    print OF  "residue: $res_id   chain: $chain_id   annotation: hbond (PDB)\n";
		}
		foreach $res_id( keys %{ $sltbrg_ctr{$chain_id} } ) {
		    print OF  "residue: $res_id   chain: $chain_id   annotation: salt bridge (PDB)\n";
		}
	    }

	    foreach $entry ( @site ) {
 		($chain_id, $res_id) = split "-", $entry;
		print OF  "residue: $res_id   chain: $chain_id   annotation: site \n";
	    }

	    close OF;
	}
	
        #  find epitope sizes for each chain 
        # use this info in deciding which chain to keep
	foreach $chain_id (@chain_ids ) { $epitope_size{ $chain_id} = 0; }
	for $ctr1 (0 .. $#chain_ids) {
	    $chain_id_1 = $chain_ids [$ctr1];
	    # output coordinates
	    open (OF, ">tmp1.pdb" ) || die "Cno tmp1.pdb: $!.";
	    print OF $coord{$chain_id_1};
	    close OF;
	    
	    for $ctr2 ($ctr1+1  .. $#chain_ids) {
		$chain_id_2 = $chain_ids [$ctr2];
		# output coordinates
		open (OF, ">tmp2.pdb" ) || die "Cno tmp2.pdb: $!.";
		print OF $coord{$chain_id_2};
		close OF;

		# footprint 1 on 2
		$command = "$geom_epitope tmp1.pdb tmp2.pdb | wc -l";
		$ret = `$command`; chomp $ret; $ret--;
		$epitope_size{ $chain_id_1} += $ret;

		# footprint 2 on 1
		$command = "$geom_epitope tmp2.pdb tmp1.pdb | wc -l";
		$ret = `$command`; chomp $ret;$ret--;
		$epitope_size{ $chain_id_2} += $ret;
	    }
	}
	# remove tmp coord files
	( -e "tmp1.pdb" ) &&  `rm tmp1.pdb`;
	( -e "tmp2.pdb" ) &&  `rm tmp2.pdb`;


	# decide which chain  to oputput if identical:
	OUTER: for $ctr1 (0 .. $#chain_ids) {
	    $chain_id_1 = $chain_ids [$ctr1];
	    next if ( $dna{$chain_id_1} );
	    next if (defined $original{$chain_id_1});

	    for $ctr2 ($ctr1+1  .. $#chain_ids) {
		$chain_id_2 = $chain_ids [$ctr2];
		next if ( $dna{$chain_id_2} );
		next if ( defined $original{$chain_id_2});

		if ( $full_chain_3{$chain_id_1} eq  $full_chain_3{$chain_id_2} ) {
		    $bigger_epi2 = (  $epitope_size{ $chain_id_2} > $epitope_size{ $chain_id_1} );
		    $equal_epi =  ( $epitope_size{ $chain_id_2} ==  $epitope_size{ $chain_id_1} );
		    $longer2 = (length $coord_seq {$chain_id_2}) >  (length $coord_seq {$chain_id_1});
		    if (  $bigger_epi2 ||   ( $equal_epi &&  $longer2) ) {
			$original{$chain_id_1} = $chain_id_2;
			foreach $chain_id ( keys %original ) {
			    if  ( $original{$chain_id} eq $chain_id_1 ) {
				$original{$chain_id} = $chain_id_2;
			    }
			}
			next OUTER;
		    } else {
			$original{$chain_id_2} = $chain_id_1;
			foreach $chain_id ( keys %original ) {
			    if  ( $original{$chain_id} eq $chain_id_2 ) {
				$original{$chain_id} = $chain_id_1;
			    }
			}

		    }
		}
	    }
	}

	

	# protein chain output
	$no_dna_chains = 0;
	foreach $chain_id (@chain_ids ) {
	    if ( $dna{$chain_id} ) {
		if ( $coord{$chain_id} =~ /U/ ) {
		    $dir = (lc $pdbname)."_rna";
		} else {	
		    $no_dna_chains ++;
		    $dir = (lc $pdbname)."_dna";
		}
	    } elsif ( defined $original{$chain_id} ) {
		$dir =  (lc $pdbname).$original{$chain_id}."_identical_chains";
	    } else {
		$dir = (lc $pdbname).$chain_id;
	    }
	    ( -e $dir) || `mkdir $dir`;
	    $filename = "$dir/".(lc $pdbname).$chain_id.".pdb";
	    open (OF, ">$filename" ) || die "Cno $filename: $!.";
	    print OF $coord{$chain_id};
	    close OF;

	    $filename = "$dir/".(lc $pdbname).$chain_id.".seq";
	    open (OF, ">$filename" ) || die "Cno $filename: $!.";
	    $seqname = (lc $pdbname).$chain_id;
	    print OF "> $seqname\n"; 
	    print_seq ($coord_seq{$chain_id});
	    close OF; 
	}	
	($no_dna_chains) && dna_pairs (); # check which chains are part of double strand

	# ligand output - if there are no ligands nothing happens here
	$dir = (lc $pdbname)."_ligands";
	foreach $chain_id (keys %hetero_coord) {
	    foreach $res_seq( keys %{ $hetero_coord{$chain_id} } ) {
		#print " ***   $chain_id   $res_seq\n";
		$filename = "$dir/".(lc $pdbname).".".$res_seq.$chain_id.".pdb";
		( -e $dir) || `mkdir $dir`;
		open (OF, ">$filename" ) || die "Cno $filename: $!.";
		print OF $hetero_coord{$chain_id}{$res_seq};
		close OF;
	    }
	}

	# symmetric units
	# $nontrivial_biomt = 0;
	if ( @biomt ) {
	    process_affine_tfmd ( @biomt );
	} elsif (  @symmetry) { # we'll skip that if there is actual biomt
	    process_affine_tfmd ( @symmetry );
	}

	# output names - for chains and ligands
	$filename = "toc";
	open (OF, ">$filename" ) || die "Cno $filename: $!.";
	foreach $chain_id (@chain_ids ) {
	    if ( $dna{$chain_id} ) {
		if ( $coord{$chain_id} =~ /U/ ) {
		    print OF  "RNA:  $chain_id \n";
		} else {	
		    print  OF "DNA:  $chain_id \n";
		}
	    } elsif (  ! defined $original{$chain_id} ) {
		$len = length ( $coord_seq{$chain_id} );
		print  OF  "chain:  $chain_id  length: $len   identical_chains: ";
		foreach $chain_id_2 (@chain_ids ) {
		    next if ( $chain_id eq $chain_id_2 );
		    if ( defined $original{$chain_id_2} && $original{$chain_id_2} eq $chain_id) {
			print  OF  " $chain_id_2";
		    }
		}
		print OF  "\n";
	    } 
	}

	$checked_empty_string = 0; # empty string is sometimes chain id, and sometimes marks ligands with no chain affiliation
	foreach $chain_id ( keys %hetero_coord ) {
	    ( $chain_id ) || ( $checked_empty_string = 1);
	    foreach $res_seq (  keys %{ $hetero_coord{$chain_id} }   ) {
		$hetnam =  $hetero_name{$res_seq};
		print OF  "ligand: $res_seq  chain: $chain_id   hetnam: $hetnam   chem_name: $chem_name{$hetnam}  synonyms: ";
		( defined  $synonym{$hetnam} ) && print  OF "( $synonym{$hetnam})  ";
		print  OF "\n";
	    }
	}
	if ( ! $checked_empty_string ) {
	    foreach $res_seq (  keys %{ $hetero_coord{""} }   ) {
		$hetnam =  $hetero_name{$res_seq};
		print OF  "ligand: $res_seq  chain: $chain_id   hetnam: $hetnam   chem_name: $chem_name{$hetnam}  synonyms: ";
		( defined  $synonym{$hetnam} ) && print  OF "( $synonym{$hetnam})  ";
		print  OF "\n";
	    }
	    
	}

	#`echo $pdbname >> $home/successes`;




    } 

}


####################################################################### 
sub process_coord_entry () {

    if (! defined $coord{$chain_id} ) {
	$coord{$chain_id} = "";
	$coord_seq {$chain_id} = "";
	$old_res_seq = -100;
	$old_res_name  ="";
    }
    $coord{$chain_id} .= $_;
    if ( $res_seq != $old_res_seq  ||  ! ($res_name eq $old_res_name) ){
    
	$old_res_seq =  $res_seq;
	$old_res_name =  $res_name;
	$res_name =~ s/\s//g;
	( (length $res_name) == 3) &&  ( $res_name = $letter_code{$res_name} ); #otherwise it's D/RNA
	$coord_seq {$chain_id} .= $res_name;
    }
}

####################################################################### 
sub print_seq (@) {
    
    my @sequence = split '',$_[0];
    my $res_ctr = 0;
    my $res;

    foreach $res ( @sequence) {
	print  OF  $res;
	$res_ctr++;
	if ( ! ($res_ctr %50 ) ){
	    print OF "\n";
	}
    }
      print OF "\n";
}


####################################################################### 
sub complement (@);
# a) check if complementary (one substr of the other, in case of different length)
# this doesn't work bc there might be breaks in one strand or someting

sub dna_pairs () {
    # make 'pairs' file in the *_dna dir

    $dir = (lc $pdbname)."_dna";
    foreach $chain_id (@chain_ids ) {
	$marked{$chain_id} = 0;	 
	$dnapdbfile{$chain_id} = "$dir/".$pdbname.$chain_id.".pdb";
    }
    @pairs = ();
    foreach $chain_id (@chain_ids ) {
	next if ( ! $dna{$chain_id} ) ;
	next if ( $marked{$chain_id} );

	$max_noc = -1;
	$max_chain_id = "";
	foreach $chain_id_2 (@chain_ids ) {
	    next if ( ! $dna{$chain_id_2} );
	    next if ( $marked{$chain_id_2} );
	    next if ( $chain_id eq $chain_id_2 );
	    # b) check space proximity 
	    $commandline = "$geom_epitope $dnapdbfile{$chain_id}  $dnapdbfile{$chain_id_2}  | wc -l";
	    $noc = `$commandline`;
	    $noc -= 1; # there is one comment line
	    if ( $noc > $max_noc ) {
		$max_noc = $noc;
		$max_chain_id = $chain_id_2;
	    }
	}
	if ( $max_noc > 0)  {
	    push @pairs, "$chain_id $max_chain_id";
	    $marked{$chain_id} = 1;
	    $marked{$max_chain_id} = 1;
	}
    } 
    if ( @pairs) {
	$filename = "$dir/pairs";
	open (OF, ">$filename" ) || die "Cno $filename: $!.";
	#for each closest pair
	foreach $pair ( @pairs) {
	    print OF "$pair\n";
	}
	close OF;
    }
} 


sub complement (@) {
    my @sequence = split '',$_[0];
    my $complement = "";
    my $nt;
    foreach $nt ( @sequence ) { # need to invert it to bcs the seq given in 5'--> 3' direction
	if ( $nt eq "A" ) { $complement = "T".$complement; next;}
	if ( $nt eq "T" ) { $complement = "A".$complement; next;}
	if ( $nt eq "C" ) { $complement = "G".$complement; next;}
	if ( $nt eq "G" ) { $complement = "C".$complement; next;}
    }
    return $complement;
}
########################################################################### 
sub trivial_tfm(@) {
    # tfm is trivial if the rotation  is identity matrix and translation is 0
    my @lines;
    my $trivial = 1;
    @lines = split '\n', $_[0];
    for $ctr ( 0 .. 2 ) {
	@aux = split " ", $lines[$ctr];
	$trivial &= ( $aux[$ctr] == 1.0 );
	for $ctr2 ( 0 .. 3 ) {
	    next if ( $ctr2== $ctr );
	    $trivial  &= ( $aux[$ctr2] == 0.0 );
	}
	last if ( ! $trivial);
    }

    return $trivial;
}

=pod
########################################################################### 
sub dye(@) {
    print "pdbparse.pl failure (note the date $pdb_date): $_[0]";
    #`echo $pdbname >> $home/failures`;
    goto TOP;
}
=cut
########################################################################### 
sub process_affine_tfmd (@) {
    my @symmetry = @_;

    @orig_chains = @chain_ids;

    foreach $symmetry_ctr (0 .. $#symmetry) {
	next if ( trivial_tfm ($symmetry[$symmetry_ctr]) );
	# save symmetry into a file
	$filename = "tmp";		
	open (OF, ">$filename" ) || die "Cno $filename: $!.";
	print OF "$symmetry[$symmetry_ctr]\n";
	close OF;
	# transform each chain from the list and save it in *_identical_chains directory
	foreach $chain_id ( @orig_chains ) {
	    print " $chain_id  ";
	    if ( defined $original{$chain_id} )  {print " $original{$chain_id} "};
	    print "\n";
	    if ( defined  $original{$chain_id} ) {
		$dir = $pdbname.$original{$chain_id}."_identical_chains";
		$in =  $pdbname.$original{$chain_id}."/".$pdbname.$chain_id.".pdb";
		(-e $in) || ( $in = $dir."/".$pdbname.$chain_id.".pdb");
	    } elsif ( $dna{$chain_id} ) {
		$in =  $pdbname."_dna/".$pdbname.$chain_id.".pdb";
		$dir = $pdbname."_dna";
	    } else {
		$in =  $pdbname.$chain_id."/".$pdbname.$chain_id.".pdb";
		$dir = $pdbname.$chain_id."_identical_chains";
	    }		    
	    ( -e $dir ) || `mkdir $dir`; 
	    $out = $dir."/".$pdbname.$chain_id.".$symmetry_ctr.pdb";
	    $commandline ="$affine  $in tmp > $out "; 
	    ( system $commandline) &&  die "Failure in affine $symmetry_ctr for  $pdbname.$chain_id.";

	    push @chain_ids, $chain_id.".$symmetry_ctr";
	    #print "orig_chains:  @orig_chains \n";
	    #print "chain ids:    @chain_ids \n\n";
	    

	    if (  defined $original{$chain_id} ) {
		$original{$chain_id.".$symmetry_ctr"} =  $original{$chain_id};
	    } else {
		$original{$chain_id.".$symmetry_ctr"} = $chain_id;
	    }

	} 
    }
}
