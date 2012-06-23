#!/usr/bin/perl -w 

use strict;
use Simple;

our %annotation;
our (@attachments, %attachment_description);
our (%path, %is_segment, %is_hi_id, @unique_chains, %copies, %sequence, %coordinates, %interface);
our (%chem_name, %synonym);
our (%nucleic, %dna);
our (%chains_in_pdb, %ligands);
our %chain_associated;
our %hetero;
our %cvg;
our $max_cvg;
our $CUTOFF_SURF_CLUSTER; 
our %renamed_to;
our %rotated_coordinates ;
our %interface_notes;
our %is_peptide;
our %pdb_entry;
our $TOO_SHORT;
our %insertion;
our %usable_copies = ();

my %letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
		'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
		'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
                'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E', 'UNK', 'X'); 

my @terminal_modifications = ("ACE", "PCA", "DIP", "NH2");
my @nucleotides =  ("C", "G", "T", "A", "U", "I", "N"); # not sure what is I - found it, for example in 1xnr.pdb
                                                        # N can be seen in 1ibm
#######################################################################################################
sub pdb_process ( @) {
    my $pdbname = $_[0];
    pdb_download ($pdbname, $path {"pdb_repository"});
    $pdb_entry{$pdbname} = `cat  $path{"pdb_repository"}/$pdbname.pdb`;
    pdb_chains ($pdbname,  "", $pdb_entry{$pdbname});
    process_pdb_coordinates ($pdbname, $pdb_entry{$pdbname} );
    pdb_annotation ($pdbname, $pdb_entry{$pdbname});
}
#######################################################################################################
sub  pdb_annotation( @) {
    my ($pdbname, $pdb_entry) = @_;
    my @lines;
    @lines = split '\n', $pdb_entry;
    my ( $chain_id_1, $seq_num_1, $ins_code_1 , $id1, $chain1 );
    my ( $chain_id_2, $seq_num_2, $ins_code_2 , $id2, $chain2 );
    my ($ctr, $note);

    foreach (@lines) {

	if (  /^SSBOND/) {

	    $chain_id_1 = substr $_, 15, 1;  $chain_id_1 =~ s/\s//g;
	    $seq_num_1  = substr $_, 17, 4;  $seq_num_1   =~ s/\s//g;
	    $ins_code_1 = substr $_, 21, 1;  $ins_code_1 =~ s/\s//g;

	    $chain_id_2 = substr $_, 29, 1;  $chain_id_2 =~ s/\s//g;
	    $seq_num_2  = substr $_, 31, 4;  $seq_num_2   =~ s/\s//g;
	    $ins_code_2 = substr $_, 35, 1;  $ins_code_2 =~ s/\s//g;

	    $chain1 = $pdbname.$chain_id_1;
	    $chain2 = $pdbname.$chain_id_2;

	    $id1 = $seq_num_1.$ins_code_1;
	    $id2 = $seq_num_2.$ins_code_2;
	    
	    ( defined  $annotation{$chain1}{$id1}  ) || ( $annotation{$chain1}{$id1}  = ());
	    $note = " forms disulphide bond with $id2";
	    ( $chain2 ne $chain1 ) && ( $note .= " in chain $chain2");
	    push @{ $annotation{$chain1}{$id1} }, $note;

	    ( defined  $annotation{$chain2}{$id2}  ) || ( $annotation{$chain2}{$id2}= ());
	    $note = " forms disulphide bond with $id1";
	    ( $chain1 ne $chain2 ) && ( $note .= " in chain $chain1");
	    push @{ $annotation{$chain2}{$id2}}, $note;
		
	} elsif (  /^HYDBND/) {

	    $chain_id_1 = substr $_, 21, 1; $chain_id_1 =~ s/\s//g;
	    $seq_num_1  = substr $_, 22, 4; $seq_num_1  =~ s/\s//g;
	    $ins_code_1 = substr $_, 27, 1; $ins_code_1 =~ s/\s//g;

	    $chain_id_2 = substr $_, 52, 1; $chain_id_2 =~ s/\s//g;
	    $seq_num_2  = substr $_, 53, 4; $seq_num_2  =~ s/\s//g;
	    $ins_code_2 = substr $_, 58, 1; $ins_code_2 =~ s/\s//g;


	    $chain1 = $pdbname.$chain_id_1;
	    $chain2 = $pdbname.$chain_id_2;

	    $id1 = $seq_num_1.$ins_code_1;
	    $id2 = $seq_num_2.$ins_code_2;
	    
	    
	    ( defined  $annotation{$chain1}{$id1}  ) || ( $annotation{$chain1}{$id1}= ());
	    $note = " forms hydrogen bond with $id2";
	    ( $chain2 ne $chain1 ) &&  ( $note .= " in chain $chain2");
	    push @{ $annotation{$chain1}{$id1} }, $note;

	    ( defined  $annotation{$chain2}{$id2}  ) || ( $annotation{$chain2}{$id2}= ());
	    $note = " forms hydrogen bond with $id1";
	    ( $chain1 ne $chain2 )  && ( $note .= " in chain $chain1");
	    push @{ $annotation{$chain2}{$id2}}, $note;
		


	} elsif (  /^SLTBRG/) {

	    $chain_id_1 = substr $_, 21, 1; $chain_id_1 =~ s/\s//g;
	    $seq_num_1  = substr $_, 22, 4; $seq_num_1  =~ s/\s//g;
	    $ins_code_1 = substr $_, 26, 1; $ins_code_1 =~ s/\s//g;

	    $chain_id_2 = substr $_, 51, 1; $chain_id_2 =~ s/\s//g;
	    $seq_num_2  = substr $_, 52, 4; $seq_num_2  =~ s/\s//g;
	    $ins_code_2 = substr $_, 56, 1; $ins_code_2 =~ s/\s//g;


	    $chain1 = $pdbname.$chain_id_1;
	    $chain2 = $pdbname.$chain_id_2;

	    $id1 = $seq_num_1.$ins_code_1;
	    $id2 = $seq_num_2.$ins_code_2;
	    
	    
	    ( defined  $annotation{$chain1}{$id1}  ) || ( $annotation{$chain1}{$id1}= ());
	    $note = " forms hydrogen bond with $id2";
	     ( $chain2 ne $chain1 )  && ( $note .= " in chain $chain2");
	    push @{ $annotation{$chain1}{$id1} }, $note;

	    ( defined  $annotation{$chain2}{$id2}  ) || ( $annotation{$chain2}{$id2}= ());
	    $note = " forms hydrogen bond with $id1";
	    ( $chain1 ne $chain2 )  && ( $note .= " in chain $chain1");
	    push @{ $annotation{$chain2}{$id2}}, $note;
		


	} elsif (  /^SITE/) { 

	    for ( $ctr = 0; $ctr<= 22; $ctr +=11) { # threee residues in each SITE record
		$chain_id_1 = substr $_, 22+$ctr, 1;$chain_id_1  =~ s/\s//g;
		$seq_num_1  = substr $_, 23+$ctr, 4;$seq_num_1   =~ s/\s//g;
		next if (! $seq_num_1 );
		$ins_code_1  = substr $_, 27+$ctr, 1;$ins_code_1 =~ s/\s//g;
		$chain1 = $pdbname.$chain_id_1;
		$id1 = $seq_num_1.$ins_code_1;
		( defined  $annotation{$chain1}{$id1}  ) || ( $annotation{$chain1}{$id1}= ());
		push @{$annotation{$chain1}{$id1}}, " is annotated as a \"site\"";
	    }
	}   
    } 
   
} 
#######################################################################################################

sub calpha_only (@) {

    my ($main_db_entry) = @_;
    my ( @lines, $atom_type, $aa_type,  $C_alpha_only);
    @lines = split '\n', $main_db_entry;
    $C_alpha_only = 1;

    foreach (@lines) {
	next if (!/^ATOM/ );
	$atom_type = substr $_, 11, 4; $atom_type =~ s/\s//g;
	$aa_type = substr $_, 17, 3; $aa_type =~ s/\s//g;
	if ( (length $aa_type) == 3 && $atom_type ne "CA" ) {
	    $C_alpha_only = 0;
	    last;
	}
    }
   
    return $C_alpha_only;
}


sub surf_clusters (@) {

    my @surf_clust;
    my $name = $_[0];
    my ($file, $fh, $ret, $command);
    my ($residue, $accesibility);
    my %accessible;
    my %shell;
    my ($line, @lines);
    my ($cluster, $cluster_size, $cluster_size_new);

    if ( ! -e  "$name.shell.pdb" || ! -s    "$name.shell.pdb" ) {
	# find surface accessibility using dssp
	$file = "$name.dssp";
	if ( ! -e $file || ! -s  $file ) {
	    $ret = `$path{"dssp"}   $name.pdb > $file`;
	    ( -e $file && -s  $file ) || die "Error: $ret\ndssp failure.";
	} else {
	    print "$name.dssp found.\n";
	}
	# read dssp
	$fh = inopen ($file);
	while (<$fh>) {
	    last if (/RESIDUE AA STRUCTURE/);
	}
	while (<$fh>) {
	    $residue      = substr $_, 5, 5;  $residue      =~ s/\s//g;
	    $accesibility = substr $_, 34, 4; $accesibility =~ s/\s//g;
	    $accessible{ $name}{$residue} = ( $accesibility > 1 );
	}
	$fh->close ;

	foreach $residue (keys %{$cvg{$name}}) {
	    if  (! defined $accessible{$name}{$residue} ) {
		my $residue_no_insert_code;
		$residue_no_insert_code = $residue;
		$residue_no_insert_code =~ s/[A-Z]//g;
		if ( ! defined $accessible{$name}{$residue_no_insert_code} ) {
		    warn  "Warning: in surf_clusters: accessibility for  $name, residue $residue_no_insert_code not defined";
		    $accessible{$name}{$residue} = $accessible{$name}{$residue_no_insert_code} = 0;
		} else {
		    $accessible{$name}{$residue} = $accessible{$name}{$residue_no_insert_code}; #ugh
		}
	    }
	}
    
	%shell = (); # this is a geometric shell of surface residues, not a unix shell
	foreach $residue (keys %{$cvg{$name}} ) {
	    $shell{$residue} = 0;
	    #print "$chain   $residue  $gaps{$residue}  $cvg{$residue}  $accessible{$chain}{$residue}\n";
	    next if ( $cvg{$name}{$residue}  > $max_cvg);
	    next if ( ! $accessible{$name}{$residue} );
	    $shell{$residue} = 1;
	}
   
	# make the pdb 
	$file = "$name.shell.pdb";
	open (OF, ">$file" ) || die "Error: Cno $file.";
	$file = "$name.pdb";
	open (IF, "<$file" ) || die "Error: Cno $file.";
	while (<IF>) {
	    $residue  = substr $_, 22, 4;  
	    $residue=~ s/\s//g;
	    ( $shell{$residue} ) && print OF;
	}
	close IF;
	close OF;
    }

    # find clusters on the surface
    $command = $path{"pdb_cluster"}."   $name.shell.pdb   5.0 ";
    $ret = `$command`;
    @lines = split '\n', $ret;
    $cluster = "";
    $cluster_size = 0;
    @surf_clust = ();
    foreach $line ( @lines ) {
	if ( $line =~ /isolated/ ) {
	    $cluster_size = 0;
	} elsif ( $line =~ /cluster size\:\s+(\d+)/ ) {
	    $cluster_size_new = $1;
	    ($cluster_size >= $CUTOFF_SURF_CLUSTER ) && ( push @surf_clust, $cluster."_");
	    $cluster_size = $cluster_size_new;
	    $cluster = "";
	} else {
	    $residue = $line;
	    $residue =~ s/\s//g;
	    $cluster .= "_$residue";
	    
	}
    }
    ($cluster_size >= $CUTOFF_SURF_CLUSTER ) && ( push @surf_clust, $cluster."_");
    
    return @surf_clust;
}
##########################################################################
sub affine (@);
sub compare_if (@);
sub dna_pairs (@);
sub trivial_tfm(@);
sub make_complex_pdb (@);

##########################################################################
sub filter_candidates (@) {
    my $chain = $_[0];
    my ($ctr, $copy, $partner);
    my ($copy_has_no_interfaces, $new_interface);
    my ($target_pdb, $target_chain_id);
    my ($copy_pdb, $copy_chain_id);
    my ($command, $ce_out, $tfm);
    my ($file, $fh, $ret);
    my $known_partner;
    my $rot_coord;
    #print "\t\t\t filtering candidates\n";
 
    $target_pdb = substr $chain, 0, 4;
    if ( length $chain > 4 ) {
	$target_chain_id = substr $chain, 4, 1;
    } else {
	$target_chain_id = "-";
    }

    @{$usable_copies{$chain}} = @{$copies{$chain}};
    # get rid of chains which have no ligands or interfaces, or no new ones
    for  ($ctr=$#{$usable_copies{$chain}}; $ctr >= 0; $ctr--) {
	$copy = $usable_copies{$chain}[$ctr];
	print "ctr:$ctr  chain:$chain  copy:$copy  \n";
	$copy_has_no_interfaces     = 1;
	foreach $partner ( keys %{$interface{$copy}} ) {
	    next if ($partner eq $chain );
	    print "\t partner:$partner    ", length $interface{$copy}{$partner}, "\n"; 
	    if (  length $interface{$copy}{$partner} ){
		$copy_has_no_interfaces = 0;
		last;
	    }
	}
	if ( $copy_has_no_interfaces ) { #get rid of this copy - not interesting
	    splice @{$usable_copies{$chain}}, $ctr, 1; # will this work properly?
                                                # I guess yes, if I am counting backwards ...
	    delete $interface{$copy};
	} else {
	    # do structural alignment for the usable_copies which do have ligands
	    $copy_pdb      = substr $copy, 0, 4;
	    if ( length $copy > 4 ) {
		$copy_chain_id = substr $copy, 4, 1;
	    } else {
		$copy_chain_id = "-";
	    }
	    $ce_out = $chain."_$copy.ce";
	    if ( ! -e $ce_out || ! -s $ce_out ) {
		( -e "pom" ) || `ln -s $path{"pom"} . `; 
		$command  = $path{"ce"}." -  ". $path {"pdb_repository"}."/$target_pdb.pdb $target_chain_id ";
		$command .= $path {"pdb_repository"}."/$copy_pdb.pdb $copy_chain_id ".$path{"scratchdir"};
		$command .= " > $ce_out";
		print $command, "\n";
		system ($command) && die "Error running CE.";
	    }
	    # read in the alignments into maps - or should I just read off 
	    # the ligand poistion in the rotated system? -> this way
	    # I can get rid of the pesky mapping process ...

	    #extract the tfm matrix: -there might be several - use the first one
	    $tfm = `grep X2 $ce_out  -A 3 | head -n3`;
	    $tfm || croak "CE output error";
	    $tfm =~ s/[XYZ][12]//g;
	    $tfm =~ s/[\(\)\+\*\=]//g;
	    foreach $partner ( keys %{$interface{$copy}}) {
		next if ($partner eq $chain );
		$rot_coord = affine ( $tfm, $coordinates{$partner});
		# interface between the original chain and the partner
		$file = "$partner.tfmd.pdb";
		$fh = outopen ($file);
		print  $fh  $rot_coord;
		$fh->close;
		
		$command = $path{"geom_epitope"}."  $chain.pdb  $file";
		$ret = `$command | grep -v min_dist`;
		if (length $ret ) {
		    # see if this interface matches any of the known ones:
		    $new_interface = 1;
		    foreach $known_partner ( keys  %{$interface{$chain}} ) {
			next if ($partner eq $copy );
			if ( compare_if ( $interface{$chain}{$known_partner}, $ret ) eq "same" ) {
			    print "\t\t if of $copy w $partner overlaps $chain w $known_partner\n";
			    $new_interface = 0;
			    last;
			}
		    }
		    if ($new_interface ) {	    
			print "\t\t new interface: $chain $partner based on $copy $partner \n";
			$interface{$chain}{$partner} = $ret;
			$rotated_coordinates{$chain}{$partner} = $rot_coord;
			$interface_notes{$chain}{$partner} = "by analogy with $copy -- $partner interface";
		    }		

		}
	    } 
	} 
    }

    if (  keys  %{$interface{$chain}} ) {
	printf "\tthe following interfaces will be considered for the chain $chain:\n";
    } else {
	printf "\tno interfaces found for the chain $chain\n";
    }
    foreach $known_partner ( keys  %{$interface{$chain}} ) {
	print "\t $known_partner\n";
    }

    # make the pdb file for the complex
    make_complex_pdb ($chain, "$chain.complex.pdb");
    #print "\t\t\t returning from filtering candidates\n";
   
}
#######################################################################
sub make_complex_pdb (@) {
    
    my ($name, $complex) = @_;
    my ($file, $file2, $fh, @struct_files);
    my ($chain_id, $some_other_id, $binding_partner, $ctr);
    my $commandline;
    
    % {$renamed_to{$name}} = ();

    $chain_id   = substr $name, 4, 1;
    $ctr = 0;
    @struct_files = ();

    $file = "$name.pdb";
    if ( ! -e $file || ! -s $file ){
 	$fh = outopen ($file);
	print $fh $coordinates{$name};
	$fh->close;
    }
   
    if ( ! $chain_id || $chain_id ne "A" ) {
	$ctr ++;
	$file = "tmp.$ctr.pdb";
	$chain_id =  "A"; 
	$commandline = $path{"pdb_rename"}."   $name.pdb $chain_id > $file"; 
	( system $commandline) &&  die "Error: pdb_rename failure.";
	push @struct_files, $file;
    } else {
	push @struct_files, "$name.pdb";
    }
    $some_other_id = $chain_id;
    $renamed_to{$name}{$name} = $some_other_id;

    foreach $binding_partner ( keys%{$interface{$name}} ) {
	(defined  $coordinates{$binding_partner}) || die "Error: $binding_partner";
	$ctr++;
	$file = "tmp.$ctr.pdb";
	$fh = outopen ($file);
	print $fh $coordinates{$binding_partner};
	$fh->close;

	if ( $hetero{$binding_partner}) {
	    push @struct_files, $file;

	} else {

	    ( ord($some_other_id)+1 > ord ("Z") ) && croak "Error: ran out of chain names.";
	    $some_other_id = chr( ord ($some_other_id)+ 1 );
	    $renamed_to{$name}{$binding_partner} = $some_other_id;
	    $ctr++;
	    $file2 = "tmp.$ctr.pdb";
	    $commandline = $path{"pdb_rename"}."   $file  $some_other_id > $file2";
	    ( system $commandline) &&  die "Error: $commandline\npdb_rename failure.";
	    push @struct_files, $file2;
	}
    }
    $commandline = "cat @struct_files > $complex";
    (system $commandline) && croak "Error concatenating files into $complex."; 
    
    foreach $file ( @struct_files ) {
	($file =~ /tmp/) && `rm $file`;
    }

    push @attachments, $complex; 
    $attachment_description{$complex} = "coordinates of $name with all of its interacting partners";

} 
##########################################################################

sub  find_surfaces ( @) {
    my $target_chain = $_[0];
    my 	$pdbname  = substr $target_chain, 0, 4;
    my	$target_chain_id = substr $target_chain, 4, 1;
    my (@chains, $chain);
    my ($file, $fh);
    my ($command, $ret);
    my $ligand;

    # interfaces for the target chain
    foreach $chain  ( @{$chains_in_pdb{$pdbname}} ) {
	$file = "$chain.pdb";
	next if ( -e $file && -s $file);
	$fh = outopen ($file);
	print $fh $coordinates{$chain};
	$fh->close;
    }

    foreach $chain  ( @{$chains_in_pdb{$pdbname}}) {
	next if ( "$chain" eq $target_chain );
	$command = $path{"geom_epitope"}."  $target_chain.pdb  $chain.pdb";
	$ret = `$command | grep -v min_dist`;
	( length $ret ) && ( $interface{$target_chain}{"$chain"} = $ret);
	#print "***$command\n***$ret****\n";
    }

    # ligand binding sites for the target chain
    if  (defined $ligands{$pdbname} &&  @{$ligands{$pdbname}} ) {

	foreach $ligand ( @{$ligands{$pdbname} } ) {
	    if ( ! defined $coordinates{$ligand} ) {
		printf " Error: ***** $ligand\n";
		exit;
	    }
	    $file = "$ligand.pdb";
	    if ( ! -e $file || ! -s $file) {
		$fh = outopen ($file);
		print $fh $coordinates{$ligand};
		$fh->close;
	    }
	    $command = $path{"geom_epitope"}."  $target_chain.pdb  $file";
	    $ret = `$command | grep -v min_dist`;
	    ( length $ret ) && ( $interface{$target_chain}{$ligand} = $ret);

	}  
    }
}


##########################################################################
sub dna_pairs (@) { #maybe I should implement something more intelligent here one day
    my %dna= @_;
    my %pair = ();
    my ($chain, $chain_2, $chain_id, $chain_id_2);
    my ($noc, $max_noc, $max_chain);
    my ($file, $fh);
    my ($pdbname, $commandline);
    my $new_name;

    foreach $chain ( keys %dna ) {
	( defined $coordinates{$chain} ) || 
	    die "Error in dna_pairs(): coord's not def for *$chain*.";
 	$file = "$chain.pdb";
	if ( ! -e $file || ! -s $file) {
	    $fh = outopen ($file);
	    print $fh $coordinates{$chain};
	    $fh->close;
	}
    }

    foreach $chain ( keys %dna ) {

	$max_noc = -1;
	$max_chain = "";
	next if ( defined $pair{$chain} );
	foreach $chain_2 ( keys %dna ) {
	    next if ( $chain  eq $chain_2 );
	    #  check space proximity
      
	    $commandline = $path{"geom_epitope"}."  $chain.pdb   $chain_2.pdb  | wc -l";
	    $noc = `$commandline`;
	    $noc -= 1; # there is one comment line
	    if ( $noc > $max_noc ) {
		$max_noc = $noc;
		$max_chain = $chain_2;
	    }
	}
	if ( $max_noc > 0)  {
	    $pair{$max_chain} = $chain;
	    $pair{$chain} = $max_chain;
	    $pdbname = substr $chain, 0, 4;
	    $chain_id = substr $chain, 4, 1;
	    $chain_id_2  = substr $max_chain, 4, 1;
	    $new_name = $pdbname.$chain_id.$chain_id_2;	

	    $coordinates{$new_name} = $coordinates{$chain}.$coordinates{$max_chain};
	    delete  $coordinates{$chain}; 	
	    delete  $coordinates{$max_chain};

	    $nucleic{$new_name} = 1;
	    delete  $nucleic{$chain}; 	
	    delete  $nucleic{$max_chain};

	    $dna{$new_name} = 1;
	    delete $dna{$chain};
	    delete $dna{$max_chain};

	    `rm $chain.pdb`;
	    `rm $max_chain.pdb`;
	    
	}
    }  

    return %dna;
}

##########################################################################
sub  pdb_copies ( @) {
    my $pdbname = shift @_;
    my @lines= split '\n', $_[0];
    my ($line, $aa_type, $chain_id, $chain_id_2, $ser_num, $res_name, $ctr);
    my %full_chain = ();
    my ($chain, $chain2, $new_chain);
    my %equal_in_principle = ();

    # copies given explicitly
    foreach $line ( @lines) {
	if ( $line =~  /^SEQRES/) {
	    $chain_id = substr $line, 11, 1;  $chain_id =~ s/\s//g; 
	    $res_name = substr $line, 19, 3;  $res_name  =~ s/\s//g;
	    next if ( (length $res_name) == 1 ); # this is DNA
	    $ser_num  = substr $line, 8, 2; #line continuation marker, basically
	    ( $ser_num == 1) && ( $full_chain{$chain_id} = "");
	    for ( $ctr=20; $ctr<=68; $ctr+=4) {
		last if ( $ctr+3 > length $line );
		$res_name = substr $line, $ctr-1, 3; $res_name  =~ s/\s//g;
		last if ( ! $res_name);
		next if  (grep {$res_name eq $_ } @terminal_modifications ); # skip terminal modifications
		(  defined $letter_code{$res_name} ) || die "Error in pdb_copies for $pdbname."; 
		$full_chain{$chain_id} .= $letter_code{$res_name};
	    }
	}   
    }

    foreach $chain_id (keys %full_chain) {
	foreach $chain_id_2 (keys %full_chain) {
	    if ( $full_chain{$chain_id} eq  $full_chain{$chain_id_2} ) {
		$equal_in_principle{$pdbname.$chain_id}{$pdbname.$chain_id_2} = 1;
	    } else {
		$equal_in_principle{$pdbname.$chain_id}{$pdbname.$chain_id_2} = 0;
	    }
	}
    }

    @unique_chains = ();
    foreach  $chain_id  ( keys %full_chain ) {
	$chain = $pdbname.$chain_id;
	@{$copies{$chain}} = ();
    }

    foreach  $chain_id  ( keys %full_chain ) {
	$chain = $pdbname.$chain_id;
	next if ( $is_peptide{$chain} ); # CE will crash, for one thing
	if (! @unique_chains ) {
	    push  @unique_chains, $chain;
	    next;
	} 
	$new_chain = 1;
	foreach $ctr ( 0 .. $#unique_chains ) {
	    $chain2 = $unique_chains[$ctr];
	    if ( $equal_in_principle{$chain}{$chain2} ) {
		$new_chain = 0;
		if ( length $sequence{$chain2} >=  length $sequence{$chain} ) {
		    push @{$copies{$chain2}}, $chain;
		} else {
		    $unique_chains[$ctr] = $chain;
		    push @{$copies{$chain}}, $chain2;
		    push @{$copies{$chain}}, @{$copies{$chain2}};
		    @{$copies{$chain2}} = ();
		}
		last;
	    }
	}
	( $new_chain )  && ( push @unique_chains, $chain);
    }

}


##########################################################################
sub  pdb_chains ( @) {
    my $pdbname = shift @_;
    my $chain_id_qr = shift @_;
    my @lines= split '\n', $_[0];
    my ($line, $aa_type, $number, $number_old);
    my ($chain_id, $modres, $modres_name, $input_chain_id);
    my @modreses = ();

    $chain_id = "+";
    $number_old = -1;

    # sample ATOM line
    # offset:
    #01234567890123456789012345678901234567890123456789012345678901234567890123456789
    #ATOM      7  C   ARG A  35      10.767  36.267  46.394  1.00 41.94           C
    @modreses = ();
    foreach $line ( @lines) {
	last if ( $line =~ /^ENDMDL/ );
	if ( $line =~ /^HEADER/ ) {
	    print "$line\n";
	    next;
	}
	if ( $line =~ /^MODRES/ ) {
	    $modres_name = substr $line, 12, 3;
	    push @modreses, $modres_name;
	    # sometimes the modified res name is the same as for nonmod (e.e. ASN)
	    ( defined $letter_code{$modres_name}) ||  ( $letter_code{$modres_name}= "X");
	    next;
	}
	$modres = 0;
        if ( $line =~ /^HETATM/ ) {
	    $aa_type = substr $line, 17, 3;
	    $aa_type =~ s/\s//g;
	    $modres = ( grep {$aa_type eq $_ } @modreses );
	} 
	if ( $line =~ /^ATOM/  || $modres ) {
	    $aa_type = substr $line, 17, 3; $aa_type =~ s/\s//g;
	    next if  (grep {$aa_type eq $_ } @terminal_modifications ); # skip terminal modifications
	    next if ( grep {$aa_type eq $_ } @nucleotides ); # this is a piece of DNA or RNA
	    next if ( $chain_id_qr  && $chain_id_qr !~   substr $line, 21, 1);
	    $input_chain_id = substr $line, 21, 1;
	    ($input_chain_id =~ /\s/) && ($input_chain_id = "");
	    if ( $chain_id ne $input_chain_id ) {
		$chain_id  = $input_chain_id;
	        $sequence{$pdbname.$chain_id} = "";
		push @{$chains_in_pdb{$pdbname}}, $pdbname.$chain_id;
	    }
	    $number = substr $line, 22, 5;
	    (  (substr $line, 26, 1) =~ /\S/ ) && ( $insertion{$pdbname.$chain_id} =1); # warning flag
	    if ( $number ne $number_old ) {
		(defined $letter_code{$aa_type}) || print "$line\n";
		$sequence{$pdbname.$input_chain_id} .= $letter_code{$aa_type};
		$number_old = $number;
	    }
	}
    }

    foreach ( keys %sequence ) {
	( !defined $insertion{$_} ) && ($insertion{$_} = 0);
    }
}

##########################################################################
sub pdb_download ( @) {

    my $pdbname = $_[0];
    my $PDB_REPOSITORY = $_[1];
    my ($qry_string, $pdbfile);

     ( -e  $PDB_REPOSITORY ) || die "Error:  $PDB_REPOSITORY does not exit.";

    $pdbname =  substr ($pdbname, 0, 4);
    if (  -e "$PDB_REPOSITORY/$pdbname.pdb" ) {
	print "$pdbname.pdb found in $PDB_REPOSITORY\n";
	return 0;
    }
    $qry_string  =  "http://www.rcsb.org/pdb/cgi/export.cgi/$pdbname.pdb?";
    $qry_string .=  "job=download;format=PDB;pdbId=$pdbname;pre=1&compression=None";
    $pdbfile = get $qry_string	|| "";
    if ( $pdbfile ) {
	open ( PDBFILE, ">$PDB_REPOSITORY/$pdbname.pdb") ||
	    die "Error: could not open $pdbname.pdb\n";
	print PDBFILE  $pdbfile;
	close PDBFILE;
	print  "wrote $pdbname.pdb\n";
	return 0;
    } else {
	print  "$pdbname retrieval failure.\n";
	return 1;
    }
}


########################################################################### 
sub trivial_tfm(@) {
    # tfm is trivial if the rotation  is identity matrix and translation is 0
    my @lines = split '\n', $_[0];;
    my $trivial = 1;
    my ($ctr, @aux, $ctr2);
    for $ctr ( 0 .. 2 ) {
	@aux = split " ", $lines[$ctr];
	$trivial = ( $trivial && ( $aux[$ctr] == 1.0 ));
	for $ctr2 ( 0 .. 3 ) {
	    next if ( $ctr2 == $ctr );
	    $trivial = ($trivial && ( $aux[$ctr2] == 0.0 ));
	}
	last if ( ! $trivial);
    }

    return $trivial;
}

########################################################################### 
sub affine (@) {

    my ($biotfm, $coordinates) = @_;
    my  @lines;
    my @aux;
    my (@A, @t, $i, $j);
    my ($ret, $x, $y, $z, $xnew, $ynew, $znew, $crap, $crap2);

    @lines = split "\n", $biotfm;
    $i = 0;
    foreach ( @lines ) {
	@aux = split;
	for $j ( 0 .. 2) {
	    $A[$i][$j] = $aux[$j];
	}
	$t[$i] = $aux[3];
	$i++;
    }
    
    @lines = split "\n", $coordinates;
    $ret = "";
    foreach (@lines) {
	next if ( ! /\S/ );
	$crap = substr ($_, 0, 30);
	$crap2 = substr ($_, 54);
	$x = substr $_,30, 8;  $x=~ s/\s//g;
	$y = substr $_,38, 8;  $y=~ s/\s//g;
	$z = substr $_, 46, 8; $z=~ s/\s//g;
	# rotate
	$xnew = $A[0][0]*$x +   $A[0][1]*$y  +  $A[0][2]*$z;
	( ! defined $A[0][2] ) &&  croak "Error: A not defined\n";
	( ! defined $z  ) &&  croak "Error: z not defined\n";
	$ynew = $A[1][0]*$x +   $A[1][1]*$y  +  $A[1][2]*$z;
	$znew = $A[2][0]*$x +   $A[2][1]*$y  +  $A[2][2]*$z;
	# translate
	$xnew += $t[0];
	$ynew += $t[1];
	$znew += $t[2];

	$ret .= sprintf "%30s%8.3f%8.3f%8.3f%s \n",
	   $crap,  $xnew, $ynew, $znew, $crap2;
    }

    return $ret;

}


########################################################################### 
sub compare_if (@) {
    my @ifc = @_;
    my ($ctr, @lines, $line, @res, $resno, $tp);
    my ($small, $smaller_list, $overlap);
    # if1 and if2 are the outputs from geom_epitope program
    # the fromati is: res_no type noc noc_with_bb distance
    $small = 10000;
    $smaller_list = 0;
    foreach $ctr ( 0 ..1 ) {
	@lines = split "\n", $ifc[$ctr];
	if ( @lines < $small ) {
	    $small = $#lines+1;
	    $smaller_list = $ctr;
	}
	%{$res[$ctr]} = ();
	foreach $line (@lines) {
	    ($resno,$tp) = split " ", $line;
	    $res[$ctr]{$resno}  = $tp;
	}
    }
    $overlap = 0;
    foreach $resno ( keys %{$res[$smaller_list]} ) {
	if ( defined $res[1-$smaller_list]{$resno} ) {
	    ($res[1-$smaller_list]{$resno} eq $res[$smaller_list]{$resno}) 
		|| die "Error matching interfaces.";
	    $overlap ++;
	}
    }

    if (  $overlap/$small > .8 ) {
	return "same";
    } else {
	return "diff";
    }
}

########################################################################### 
sub compare_if_w_cluster (@) {

    my ($ifc,$cluster) = @_;
    my ($ctr, @lines, $line, %res, $resno, $tp);
    my ($cluster_size, $if_size, $overlap);
    # ifc is the output from geom_epitope program
    # the format is: res_no type noc noc_with_bb distance
    # cluster is a list of residues separated by "_"

    @lines = split "\n", $ifc;
    $if_size = 0;
    foreach $line (@lines) {
	($resno,$tp) = split " ", $line;
	$res{$resno}  = $tp;
	$if_size ++;
    }
    $overlap = 0;
    $cluster_size = 0;
    foreach $resno ( split "_", $cluster ) {
	if ( defined $res{$resno} ) {
	    $overlap ++;
	}
	$cluster_size ++;
    }

    if (  $overlap/$cluster_size > .8 ||  $overlap/$if_size  > 0.8 ) {
	return "same";
    } else {
	return "diff";
    }
}

########################################################################### 
sub process_pdb_coordinates (@) {

    my $pdbname = $_[0];
    my @lines = split '\n', $_[1];
    my ($line, $chain_id, $res_name, $aa_type);
    my  %found = ();
    my ($remark_num , @aux, $aux2, @biomt_applies_to, @biomt, @biomt_chains, $biomt_ctr);
    my ($cont, $continuation, $hetnam, $descr);
    my $have_na = 0;
    my %is_rna = ();
    my $chain;
    my %mydna = ();
    my $res_seq;
    my @modreses = ();
    my ($modres_name, $modres);
    my $ligand_name;

    print "\t processing coordinates for $pdbname\n";

    # copies given explicitly
    foreach $line ( @lines) {
	if ( $line =~  /^SEQRES/) {
	    $chain_id = substr $line, 11, 1;  $chain_id =~ s/\s//g; 
	    $res_name = substr $line, 19, 3;  $res_name  =~ s/\s//g;
	    if ( (length $res_name) == 1 ){  # this is DNA or RNA
		$have_na =  1;
		( $res_name =~ /U/) && ($is_rna{$pdbname.$chain_id} = 1);
		next;
	    }
	    ( ! defined $found{$chain_id}  ) && ($found{$chain_id} = 1);
	}   
    }

    

    # pdb coordinates
    foreach $chain ( @{$chains_in_pdb{$pdbname}} ) {
	next if ( defined $coordinates{$pdbname.$chain} );
	$coordinates{$chain} = "";
	foreach $line ( @lines) {
	    last if ( $line =~ /^ENDMDL/ );
	    if ( $line =~ /^MODRES/ ) {
		$modres_name = substr $line, 12, 3;
		push @modreses, $modres_name;
		# sometimes the modified res name is the same as for nonmod (e.e. ASN)
		( defined $letter_code{$modres_name}) ||  ( $letter_code{$modres_name}= "X");
		next;
	    }
	    $modres = 0;
	    if ( $line =~ /^HETATM/ ) {
		$aa_type = substr $line, 17, 3;
		$aa_type =~ s/\s//g;
		$modres = ( grep {$aa_type eq $_ } @modreses );
	    } 
	    if ( $line =~  /^ATOM/ || $modres) {
		$aa_type = substr $line, 17, 3; $aa_type =~ s/\s//g;
		next if  (grep {$aa_type eq $_ } @terminal_modifications ); # skip terminal modifications
		$chain_id = substr $line, 21, 1;  $chain_id =~ s/\s//g; 
		next if ( $chain_id  && $chain_id  ne substr $chain, 4, 1 );
		$coordinates{$chain} .= $line."\n";

	    } elsif ( $line =~  /^HETATM/ ) {
		$chain_id = substr $line, 21, 1;  $chain_id =~ s/\s//g; 
		next if (  $chain_id  &&  ($chain_id  ne  substr $chain, 4, 1) );
		$res_name = substr $line, 17, 3; $res_name=~ s/\s//g;
		next if  (grep {$res_name eq $_ } @terminal_modifications ); # skip terminal modifications
		next if ( ! defined $letter_code{$res_name} ); # this assumes that MODRES where processed
                                                # field was already processed, and the name
                                                # for the modifed residue taken care of in %letter_code
		$coordinates{$chain} .= $line."\n";
	    } 
	}
    }

    # copies given in the BIOMT
    foreach $line ( @lines) {
	if ( $line =~  /^REMARK/) {
	    #generate biomolecule
	    $remark_num = substr $line, 7, 3;
	    next if ($remark_num != 350  );  # remark 350 -- BIOMT
	    (substr ($line, 11,59 ) !~ /\S/  ) && (@biomt_applies_to = ());
	    if ( $line =~ /APPLY / ) {
		@aux  = split '\:', $line;
		$aux2 = pop @aux;  
		$aux2 =~ s/[\s\.\,]//g;
		if ( $aux2 eq "NULL" ) {
		    push @biomt_applies_to, "";
		} else {
		    @aux  = split'', $aux2;
		    push @biomt_applies_to, @aux;
		}
	    } elsif  ( $line =~ /BIOMT(\d) / ) {
		$biomt_ctr  = (substr $line, 20, 3) - 1;
		if ( $1 == 1 ) {
		    $biomt[$biomt_ctr] = "";
		    if ( ! @biomt_applies_to && $biomt_ctr) { # in case one "APPLY" line refers to several BIOMT lines
			@{$biomt_chains[$biomt_ctr]} = @{$biomt_chains[$biomt_ctr-1]};
		    } else {
			@{$biomt_chains[$biomt_ctr]}= @biomt_applies_to;
		    }
		    @biomt_applies_to = ();
		}
		$biomt[$biomt_ctr] .= (substr $line, 23)."\n";
	    }
	}
    }   


    for $biomt_ctr ( 0 .. $#biomt ) {
	if ( trivial_tfm( $biomt[$biomt_ctr] ) ){
	    #printf "  $biomt_ctr is trivial \n";
	} else {
	    foreach $chain (  @{$biomt_chains[$biomt_ctr]} ) {
		# does the rotated chain exist?
		next if ( defined $coordinates{$pdbname.$chain.$biomt_ctr} ); 
		# this is not very thorough, but with all the mapping that I do 
		# this should be OK
		next if (!  defined $coordinates{$pdbname.$chain} );
		# rotate them 
		$coordinates{$pdbname.$chain.$biomt_ctr} =  affine ( $biomt[$biomt_ctr], $coordinates{$pdbname.$chain} ); 
		push @{$chains_in_pdb{$pdbname}}, $pdbname.$chain.$biomt_ctr;
		$sequence{$pdbname.$chain.$biomt_ctr} = $sequence{$pdbname.$chain};
	    } 
	    
	} 
    }


    # ligands:
    %found = ();
    %nucleic = ();
    foreach $line ( @lines) {
	last if ( $line =~ /^ENDMDL/ );
	if ( length $line > 6 ) {
	    $continuation = substr $line, 8, 2;  $continuation  =~ s/\s//g;
	} else {
	    $continuation = "";
	}
	if ( $line =~  /^HETATM/ ) {
	    $hetnam = substr $line, 17, 3; $hetnam=~ s/\s//g;
	    next if ( $hetnam eq "HOH");
	    next if  (grep {$hetnam eq $_ } @terminal_modifications ); # skip terminal modifications
	    next if ( defined $letter_code{$hetnam} ); # this assumes that MODRES 
                                                # field was already processed, and the name
                                                # for the modifed residue taken care of in %letter_code
	    $chain_id = substr $line, 21, 1;  $chain_id =~ s/\s//g; 
	    $res_seq  = substr $line, 22, 4;  $res_seq  =~ s/\s//g; 
	    $ligand_name = $pdbname.$chain_id.$hetnam.$res_seq;
	    $coordinates{$ligand_name} .= $line."\n";
	    ( defined $found{$ligand_name} ) || ( $found{$ligand_name} = 1 );
	    $chain_associated{$ligand_name} = $chain_id;
	    $hetero{$ligand_name} = $hetnam;

	} elsif ( $line =~  /^HETNAM/) {
	    $cont = ($continuation && $continuation>1) ;
	    $hetnam   = substr $line, 11, 3; $hetnam  =~ s/\s//g;
	    next if  (grep {$hetnam eq $_ } @terminal_modifications ); # skip terminal modifications
	    $descr    = substr $line, 15, 55;  $descr =~ s/\s+/ /g; 
	    @aux = split "", $descr;
	    while ( $aux[0] =~ /\s/ ){shift @aux};
	    while ( $aux[$#aux] =~ /\s/ ) {pop @aux};
	    $descr = join "", @aux;
	    ( $cont ) || ( $chem_name{$hetnam}  = lc $descr );
	    ( $cont ) && ( $chem_name{$hetnam} .= lc $descr );

	} elsif ( $line =~  /^HET   /) {
	    $hetnam   = substr $line, 7, 3; $hetnam  =~ s/\s//g;
	    $descr    = substr $line, 30, 40;  $descr =~ s/\s+/ /g; 
	    if ( $descr =~ /\S/ ) {
		@aux = split "", $descr;
		while ( $aux[0] =~ /\s/ ){shift @aux};
		while ( $aux[$#aux] =~ /\s/ ) {pop @aux};
		$descr = join "", @aux;
		( $cont ) || ( $chem_name{$hetnam}  = lc $descr );
		( $cont ) && ( $chem_name{$hetnam} .= lc $descr );
	    }

	} elsif ( $line =~  /^HETSYN/) {
	    $cont = ($continuation && $continuation>1) ;
	    $hetnam   = substr $line, 11, 3; $hetnam =~ s/\s//g;
	    $descr    = substr $line, 15, 55; $descr  =~ s/\s+/ /g;
	    ( $cont ) || ( $synonym{$hetnam}  = $descr );
	    ( $cont ) && ( $synonym{$hetnam} .= $descr );

	} elsif ($have_na && $line =~/^ATOM/ ) {
	    $res_name = substr $line, 17, 3; $res_name=~ s/\s//g;
	    next if (length $res_name != 1 ); # this is protein
	    $chain_id = substr $line, 21, 1;  $chain_id =~ s/\s//g; 
	    $ligand_name = $pdbname.$chain_id;
	    $nucleic{$ligand_name} = 1;
	    (defined  $is_rna{$ligand_name} ) ||  ( $mydna{$ligand_name} = 1 );
	    $coordinates{$ligand_name} .= $line."\n";
	} 
    }
    # get rid of imbecils who put 100-letter chemical names in here
    foreach ( keys %chem_name ) {
	( length $chem_name{$_} > 20 )  && ( $chem_name{$_} = $_) ;
    }

    # dna is given as two chains - check which two go together
    %dna = dna_pairs (%mydna);


    @{$ligands{$pdbname}} = keys %found;
    push @{$ligands{$pdbname}} , keys %nucleic;

    # the chains shorter than TOO_SHORT we'll consider peptides,
    # and treat like ligands
    foreach $chain ( @{$chains_in_pdb{$pdbname}} ) {
	(defined  $sequence{$chain}) || die "Error: sequence $chain not defined";
	if ( length $sequence{$chain} < $TOO_SHORT ) {
	    $is_peptide{$chain} = 1;
	    push @{$ligands{$pdbname}}, $chain;
	} else {
	    $is_peptide{$chain} = 0;
	}
    }
}


1;
