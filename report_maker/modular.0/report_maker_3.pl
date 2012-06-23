#! /usr/bin/perl -w -I/home/i/imihalek/projects/report_maker/modular

use strict;

use Boot;
use Model_structure;
use Pdb;
use Report_utils;
use Text;
use Pymol;
use Parse_blast;
use Parse_HSSP;


sub boot();
sub chain_chapter (@);
sub count_representatives ();
sub determine_cvg_closest_to_max (@);
sub difference_analysis ();
sub extract_pdb_chains();
sub fctl_surf_process (@);
sub filter_candidates (@);
sub find_uniprot (@);
sub input_parse ();
sub ligand_binding ();
sub pdb_description  (@);
sub pdb_intro_text (@);
sub pdb_uniprot_compare (@);
sub process_pdb_coordinates (@);
sub results_pooling();
sub run_ET (@);
sub seq_selection_by_clustering (@);
sub seq_selection_by_bitval ();
sub structure_match ();
sub uniprot_description(@);
sub uniprot_intro_text (@);
############# result pooling ##############
sub interface_clusters ();
sub diff_analysis ();
sub wrap_up ();



################################################################################
#
#    CONSTANTS
#
################################################################################

our $FRAGMENT_LENGTH = 0.75;
our $TOO_SHORT  = 20;
our $TOO_FEW_SEQS  = 10;
our $MAX_ID = 0.99;
our $EVALUE     =  1.e-10;
our $PID_IDENTICAL = 95;
our $PID_LOWEST_ACCEPTABLE = 60;
our $max_gaps       = 0.3;
our $top_percentage = 25;
our $top_percentage_surface = 25;
our $max_cvg        = $top_percentage/100;
our $max_cvg_surface = $top_percentage_surface/100;
our $CUTOFF_SURF_CLUSTER = 5;
our $HOME = "/home/i/imihalek";
our $home = `pwd`; chomp $home;

################################################################################
#
#    GLOBAL ARRAYS
#
################################################################################

our ($id, $id_type, $main_db_entry);
our %aa_freqs = ();
our $alistat_footnote = 0;
our %annotation = ();
our (@attachments, %attachment_description);
our %chain_associated = ();
our (%chains_in_pdb, %ligands);
our (%chem_name, %synonym); # this is for ligands
our %coordinates   = ();
our %copies        = ();
our %cvg  = ();
our %cvg_rank  = ();
our %end   = ();
our %gaps = ();
our %hetero = ();
our %interface     = ();
our %interface_notes   = ();
our %is_hi_id      = ();
our %is_segment    = ();
our %is_peptide    = ();
our %is_hssp    = ();
our (%nucleic, %dna);
our %options = ();
our %pdb_entry = ();
our $pdb_short;
our %path = ();
our %pdb_resnum  = ();
our @pics;
our %pid   = ();
our @regions = ();
our %rotated_coordinates   = ();
our %sequence      = ();
our %sequential = ();
our %start = ();
our $structure = 0;
our $structure_used_at_least_once = 0;
our %subst= ();
our @texfiles;
our %type = ();
our %uniprot_sequence  = ();
our @unique_chains = ();
our %usable_copies = ();
our %var  = ();



################################################################################
#
#    STARTING (AND ENDING) POINT
#
################################################################################

boot();
input_parse ();
text_format();
wrap_up ();

print "\nreport maker done.\n";

################################################################################
#
#    MODULES
#
################################################################################

sub chain_chapter (@) { 

    my $name = $_[0];
    my $tex_string = "";
    my ($fh, $file, $ret);

    printf "\tstarting chapter for $name\n";
    $tex_string = "\\section\{Chain $name\} \n";

    if (  ($id_type eq "UNIPROT" || defined $options{"MODEL}"} )  && $structure   ) {
	$tex_string .= rationale ($name);
    }
    if (  $id_type eq "UNIPROT"  &&  ($id ne $name)  &&  ($pid{$name} < 100)  ) {
	if ( defined  $options{"MODEL"} ) {
	    map_qry ( $id, $name, $options{"MODEL_ALMT"}); # find mapping between the query and the model
	} else {
	    map_qry ( $id, $name, ""); # find mapping between the query and the model
	}
    }

    if (  ($id_type eq "UNIPROT" &&  $is_hi_id{$name} || defined $options{"MODEL"}) && ($id ne $name)  ) {
    } else {
	$ret = find_uniprot (@_);
	$ret || return $ret; #couldn't find sequences
	( $ret eq "ok" ) && return $ret; # emitting was taken care of
	if ( $id_type eq "UNIPROT"  && @regions) {
	    $tex_string .= not_enough_full_length_seqs_blurb ($id);
	}
	$tex_string .= $ret;
    }

    if ($structure) {
	$ret = seq_selection_by_clustering($name);
	$ret || return $ret; #couldn't find sequences
	$tex_string .= $ret;
	if ($id_type eq "PDB"  && $pdb_short) {
	    $tex_string .= difference_analysis();
	}
    }

    printf "emitting from chain_chapter\n";
    emit ("$name.tex", $tex_string);

    return "ok";
}

################################################
sub determine_cvg_closest_to_max (@) {
    my ($name) = @_;
    my $tex_string ="";
    my ($rank, $coverage);
    my ($min_dist, $dist,$min_dist_rank,  $min_dist_cvg  );

    $min_dist = 2.0;
    while ( ($rank,  $coverage) =  each  %{$cvg_rank{$name}} ) {
	$dist = abs ($coverage - $max_cvg); #max_cvg is global
	if ( $min_dist >  $dist ) {
	    $min_dist = $dist;
	    $min_dist_rank = $rank;
	    $min_dist_cvg = $coverage;
	}
    }
    print "\tthe coverage closest to $max_cvg: $min_dist_cvg (rank $min_dist_rank)\n";
    $tex_string  = "\\subsection{Top ranking residues in $name and their position on the structure}\n"; 
    $tex_string  .= "In the following we consider residues ranking among the top ". percent ($min_dist_cvg, 1) ."\\%"; 
    $tex_string  .= " of residues in the protein."; 
    ( $min_dist > 0.01 ) && 
	( $tex_string  .= " (the closest this analysis allows us to get to $top_percentage\\%)"); 
    $tex_string .= ". ";
    $tex_string .= clusters_text ($name, $min_dist_cvg, $min_dist_rank); 
    $tex_string .= fctl_surf_text($name, $min_dist_cvg, $min_dist_rank);
    $tex_string .= hypo_surf_text($name, $min_dist_cvg, $min_dist_rank); 

    return $tex_string;
   
}

################################################
sub difference_analysis (){
     printf "\tin dif analysis\n";
}

################################################
sub extract_pdb_chains(){

    my ($chain, $chain2, $chain_ret, $ctr);
    my ($pdbname, $chain_id);
    my $too_short;
    my @unique_chains_copy;
    my @not_enough_seqs_chains;
    printf "\textracting PDB chains\n";

    $structure = 1;

    if ( defined $options{"MODEL"}) {

	$pdbname =  $options{"MODEL"};
	$pdbname =~ s/\.pdb$//;  
	$pdb_entry{$pdbname} = `cat  $options{"MODEL"}`;
	pdb_chains ($pdbname, "", $pdb_entry{$pdbname});# fils $chains_in_pdb and sequence hashes
	if ( @{$chains_in_pdb{$pdbname}}  == 1 ) {
	    $chain = $pdbname;
	    $is_hi_id{$chain}  = 0;
	    push @unique_chains, $chain;
	    $copies{$chain} = ();
	} else {
	   failure_handle ($options{"MODEL"}." contains more than one chain.\n"); 
	}
	process_pdb_coordinates ( $pdbname, $pdb_entry{$pdbname}  ); 
        pdb_annotation ( $pdbname, $pdb_entry{$pdbname} ); 

    } elsif ( $id_type eq "PDB" ) {

	$pdbname = $id;
	if ( ! defined $pdb_entry{$pdbname} || ! $pdb_entry{$pdbname} ) {
	    pdb_download ($pdbname, $path {"pdb_repository"});
	    $pdb_entry{$pdbname} = `cat  $path{"pdb_repository"}/$pdbname.pdb`;
	}
        # CHECKPOINT
	# is this bare backbone maybe?
	if ( calpha_only ($pdb_entry{$pdbname})  ) {
	    failure_handle ("the PDB file $id consists of C-alpha's only.\n");
	} 

	pdb_chains ($pdbname, "", $pdb_entry{$pdbname});# fils $chains_in_pdb and sequence hashes
	foreach $chain(  @{$chains_in_pdb{$pdbname}}  ) {
	    $is_hi_id{$chain}  = 1;
	    $is_segment{$chain} = 0;
	}
	process_pdb_coordinates ( $pdbname, $pdb_entry{$pdbname} );
        pdb_annotation ( $pdbname, $pdb_entry{$pdbname} );
	if ( @{$chains_in_pdb{$pdbname}}  == 1 ) {
	    $chain = $chains_in_pdb{$pdbname}[0];
	    push @unique_chains, $chain;
	    $copies{$chain} = ();
	} else {
	    pdb_copies($pdbname, $pdb_entry{$pdbname}); # find which chains are (in principle) copies of each other
	}

        # CHECKPOINT
	# are the chains long enough ?
	$too_short = 1;
	foreach ( @unique_chains ) {
	    if ( length $_ < $TOO_SHORT )  {
		$too_short = 0;
		last;
	    }
	}
	$too_short && failure_handle ("all chains in $pdbname shorter than $TOO_SHORT residues"); 

	# remove peptides from the unique chain list
	@unique_chains_copy = @unique_chains;
	@unique_chains = ();
	while ( $chain =  shift @unique_chains_copy ) { 
	    if ( $is_peptide{$chain} ) {
		print " \t$chain is a peptide: @unique_chains\n";
	    } else {
		push @unique_chains, $chain;
	    }
	}

	foreach ( @unique_chains ) { 
	    run_HSSP ($_) &&  last; # if there is no HSSP available, the fuction will return 1
	    HSSP_chain_check ($_);  # I want to change my mind if the chain that was chosen is not the one in HSSP
  	} 
 
	pdb_intro_fig ($id); 


    } else { # the input was uniprot - we have resolved the chain issues by this point 

	for ($ctr=0; $ctr<=$#unique_chains;  $ctr++ ) {
	    $chain = $unique_chains[$ctr];
	    $pdbname = substr $chain, 0, 4;
	    if ( ! defined $pdb_entry{$pdbname} || ! $pdb_entry{$pdbname} ) {
		pdb_process ( $pdbname );
	    }
	}
	# clean up - get rid of the pdb's which are c-alpha only 
	for ($ctr=$#unique_chains; $ctr >= 0; $ctr-- ) {
	    # is there ever such case that pdb is one chain full, and one chain backbone only?
	    if ( calpha_only($pdb_entry{$pdbname}) ) {
		print "\t note: $pdbname is C-alpha only\n";
		splice @unique_chains, $ctr, 1;
		undef $copies{$chain};
	    }
	}

	foreach $chain ( @unique_chains ) {
	    run_HSSP ($chain);
	    HSSP_chain_check ($chain); 
	    foreach $chain2 ( $chain, @{ $copies{$chain} } ) {
		$pdbname = substr $chain2, 0, 4;
		if ( ! defined $pdb_entry{$pdbname} || ! $pdb_entry{$pdbname} ) {
		    pdb_process ( $pdbname );
		}
	    }
	}
	
    }


    @unique_chains_copy = @unique_chains;
    @unique_chains = ();
    @not_enough_seqs_chains = ();
    while ( $chain = shift @unique_chains_copy ) {
	print "\t\t to fctl surf process for chain $chain \n";
	if ( fctl_surf_process ($chain)) {
	    push @unique_chains, $chain;
	} else {
	    push @not_enough_seqs_chains, $chain;
	}
    }
    # CHECKPOINT
    # enough seqs for at least one of the chains 
    (@unique_chains) ||  return "";



    if ( $id_type eq "PDB" ) { # comment on chain length and sequnce availability for the intro
	pdb_chain_comment ($id, @not_enough_seqs_chains); # unique_chains is global; thisi is text emitting function
    }

    return "ok";
}

################################################
sub fctl_surf_process (@) { 
    my $chain = $_[0];
    my ($chain2, $pdbname);
    printf "\n\tin fctl_surf_process: $chain ********\n";

    foreach $chain2 ( $chain, @{ $copies{$chain} } ) {
	$pdbname  = substr $chain2, 0, 4;
	find_surfaces ($chain2, $pdb_entry{$pdbname});
	print "\tchain: $chain2  \n";
	print "\t\t interfaces: ", (join " ",  keys %{$interface{$chain2}}),"\n";
    }
    filter_candidates ($chain); # get rid of duplicates bringing in no new info

 
    $structure = 1;
    return chain_chapter ($chain);    

 }


##############################################
sub find_uniprot (@) { 

    printf "\tfind_uniprot\n";
    my $name = $_[0];
    my ($pct_identity, $descriptor);

    if ( ($id_type eq "PDB") || $structure ) {

	( defined $sequence{$name}) || die "Error: Undefined sequence in formatted_sequence()";
	do_blast ($sequence{$name}, $name, $path {"uniprot_for_blast"}, 
		  $path{"blast"}, 8, "$name.blast");
	($descriptor,$pct_identity)  = parse_blast_8_on_uniprot ("$name.blast");
	$descriptor || return $descriptor;
	$structure = 1;
	return uniprot_description("", $name, $descriptor, $pct_identity);
	
    } elsif ( $id_type eq "UNIPROT" ) {
	my ($uniprot_id, $seq);
	$structure = 0;
	# uniprot id ? uniprot seq?
	($uniprot_id, $seq)  = seq_from_uniprot ($main_db_entry);
	$sequence{$uniprot_id} = $seq; # save for later
	push @attachments, "$id.seq";
	$attachment_description{"$id.seq"} = "the query (target) sequence; $id in fasta format";
	return uniprot_description( "intro.tex", $id, $main_db_entry, 100); 

    } else  {
	die "Error: Error in find_uniprot ().";
    }
    
}


################################################
sub input_parse () {
  
    sub determine_id_type ();
    
    ( ! @ARGV )  && die "Error: Usage: report_maker.3.pl  <uniprot or PDB identifier>.\n";

    # check if it is a .cmd file
    if ( $ARGV[0] =~ /\.cmd$/) {
	print "$ARGV[0] is a command file.\n";
	read_options ($ARGV[0]);
	$id = $options{"NAME"};
    } else {
	$id = shift @ARGV;
    }

     ($id_type, $main_db_entry) = determine_id_type ();

     if ( $id_type eq "PDB" ) {
	 pdb_description ($id, $main_db_entry); 
     } else {
	 chain_chapter ($id) || failure_handle ("not enough sequences found.");
     }
    
} 

################################################ 
sub pdb_description  (@) {
    my $intro = 1;
    my $emphasis = 1;
    my $ret;
    printf "\t PDB intro\n";
    emit ( "intro.tex", pdb_intro_text ( $intro, $emphasis, @_));
    $ret = extract_pdb_chains();
    $ret || failure_handle ("not enough sequences found.");
}

################################################
sub pdb_uniprot_compare (@) {

    my $current_chain = shift @_;
    my $uniprot_descr = shift @_;
    my ($uniprot_id, $seq);
   
    printf "\tcomparing PDB and uniprot\n";
    
    ($uniprot_id, $seq) = seq_from_uniprot ($uniprot_descr);
    $uniprot_sequence{$uniprot_id} = $seq;

    $pdb_short = 0;
    ( (length $sequence{$current_chain})/( length $uniprot_sequence{$uniprot_id}) <  0.8 ) &&
	( $pdb_short = 1);

    if ($pdb_short) {
	# seq_selection_by_bitval (); # on the uniprot sequence
	print " ---> seq_selection_by_bitval () commented out.\n";
    } 
}


################################################
sub run_ET (@) { 

    my ($name, $query, $msffile, $skip_query) = @_;
    my $command;
    my ($alignment_no, $residue, $typ, $rank, $variability, $substitutions,  $rho, $coverage,  $gapp);
    my ($file, $fh);
    my $found;
    my $tex_string;
    my @aux;
    my $ctr;

    printf "\tin run ET for $name\n";

    #trace
    if ( modification_time ("$name.ranks") < modification_time ("$name.msf") )  {
 	$command = $path{"etc"}." -p $msffile -x $query";
	($structure) && ( $command .= " $query.pdb -c ");
	($skip_query) && ( $command .= " -skip_query ");
	$command .= " -o $name >& /dev/null";
	(system $command) &&  die "Error: $command\nError running etc.";
    }
    # make etv file
    if ($structure) {
	$structure_used_at_least_once = 1;
	if ( modification_time ("$name.etvx") < modification_time ("$name.ranks") )  {	
	    `echo $name >  $name.etvx`;
	    `echo ~pdb   >> $name.etvx`;
	    `cat $name.pdb   >> $name.etvx`;
	    `echo ~ET_ranks   >> $name.etvx`;
	    `cat $name.ranks >> $name.etvx`;
	    `echo  ~tree >> $name.etvx`;
	    `cat $name.pss.nhx >> $name.etvx`;
	    `echo ~z_scores >> $name.etvx`;
	    `cat $name.cluster_report.summary >> $name.etvx`;
	}
	push @attachments, "$name.etvx";
	$attachment_description {"$name.etvx"} = "ET viewer input file for $name"; 
    }

    # import trace results
    #### ranks
    $alignment_no =$residue =$typ =$rank =$variability =$substitutions =$rho  =$coverage = $gapp = 0;
    $file = "$name.ranks_sorted";
    $fh = inopen ($file);
    $found = 0;
    $ctr = 0;
    while ( <$fh> ) {
	next if ( /%/ );
	next if ( !/\S/ );
	chomp;
	( $alignment_no,  $residue,  $typ,  $rank,  $variability,  $substitutions, $rho, $coverage, $gapp) = split;
	next if ( $residue eq "-" );
	$found = 1;
	$pdb_resnum{$name}[$ctr] = $residue;
	$type{$name}{$residue} = $typ;
	$var{$name}{$residue}  = $variability;
	$subst{$name}{$residue}= $substitutions;
	$cvg{$name}{$residue}  = sprintf "%.2f", $coverage;
	$gaps{$name}{$residue} = $gapp;
	$ctr ++;	
    }

    @aux = sort { $a <=> $b } ( keys %{$type{$name}} );
    $ctr = 0;
    foreach $residue (@aux) {
	$ctr++;
	$sequential{$name}{$residue} = $ctr;
    }

    $fh->close;
    ######### sanity:
    ($found) || die "Error: No residue fo $name found in $name.msf";

    #### coverage and clustering
    if ($structure ) {
	$file = "$name.cluster_report.summary";
	$fh = inopen ($file);
	while ( <$fh> ) {
	    next if ( /%/ );
	    next if ( !/\S/ );
	    chomp;
	    ( $rank,  $coverage) = split;
	    $cvg_rank{$name}{$rank} = sprintf "%.2f", $coverage;
	}
	$fh->close;
    }

    #### read aa frequencies at each position in the almt
    $file = "$name.aa_freqs";
    $fh = inopen ($file);
    while ( <$fh> ) {
	next if ( /%/ );
	next if ( !/\S/ );
	chomp;
	@aux = split;
	next if ( $aux[1] eq '.' );
	%{$aa_freqs{$name}{$aux[2]}} =  @aux[3 .. $#aux];
    }
    $fh->close;

 
    #text
    $tex_string =  primary_seq_text ($name);

    if ( $structure ) {
	# from this function we go to structure-related pieces of text
	 $tex_string .= determine_cvg_closest_to_max($name);
    }

    return $tex_string;

}

################################################
sub results_pool () { 
    printf "\tpooling results\n";
}

################################################
sub seq_selection_by_bitval () { 

    my @fastafiles;
    my $fastafile;
     my $name;
    my $command;
    my $completeness;
    my $msffile;
    
    printf "\tin seq_selection_by_bitval\n";
    @fastafiles = blast2fasta($id, $sequence{$id}, 1);
    $fastafiles[0] || return $fastafiles[0];
    $completeness = shift @fastafiles;
    if ( $completeness eq "full" ) {
	print "\t\tfull sequence coverage in returned sequences.\n";
    } else {
	print "\t\tcoverage in ", $#fastafiles+1, " regions.\n";
    }
    foreach $fastafile ( @fastafiles ) {
	$msffile = $fastafile;
	$msffile =~ s/\.fasta/\.msf/;
	$name = $fastafile;
	$name =~ s/\.fasta//;
	if ( modification_time ($msffile) < modification_time ($fastafile) )  {
	    # muscle
	    print "\t\tmuscle ... \n";
	    $command = $path{"muscle"}." -in $fastafile -out tmp.afa >& /dev/null";
	    (system $command) &&  die "Error: $command\nError running muscle.";
            # remove identical
	    print "\t\tremove identical \n";
	    $command = $path{"remove_id_from_afa"}. " tmp.afa tmp2.afa  $id $MAX_ID ";
	    (system $command) &&  die "Error: $command\nError removing identical from afa.";  
	    # convert to msf format
	    $command = $path{"afa2msf"}."  tmp2.afa > $name.msf ";
	    (system $command) &&  die "Error: Error converting to msf.";
	    `rm tmp.afa tmp2.afa`;
	    
	}
	$structure = 0;
	print "\t alignment $msffile done.\n";

	return run_ET ($name, $id, $msffile, "");
    }
}

################################################
sub seq_selection_by_clustering (@) { 

    my $name = $_[0];
    my ($completeness, $fastafile);
    my ($command, $ret, $cmd_file);
    my (@aux, $names_choice);
    my $query;

    printf "\tin seqsel by clustering for $name\n";
    #defined $options{"MODEL"} && exit;
    # "query" depends on whether we are modelling or we have the actual structure
    $query = $name; 
    ( defined $options{"MODEL"} ) && ( $query = $id);

    $is_hssp{"$name.msf"} = 0;
    if ( ! -e "$name.msf" || ! -s "$name.msf") {
	# hssp
	$ret = "failure or model";
	(defined $options{"MODEL"}) || ($ret = HSSP2msf ($name));
	# from scratch
	if ( $ret ) { #HSSP failure or MODEL

	    print "\tetc seq selection\n";
	    # blast and obtain a "clean" msf
	    if ( defined $options{"MODEL"}) {
		($completeness, $fastafile) = blast2fasta ($name, (substr $sequence{$id}, $start{$name}-1, $end{$name} - $start{$name}+1), 0);
	    } else {
		($completeness, $fastafile) = blast2fasta ($name, $sequence{$name}, 0);
	    }
	    ($completeness eq "full") ||  die ("Error: unexpected in seq_selection_by_clustering.");
	    ( $fastafile ) || return $fastafile; # not enough seqs found for this chain
	    #go back to the msf - this fasta is actually afa
	    print "\t\tafa2msf \n";
	    $command = $path{"afa2msf"}." $fastafile > tmp.msf";
	    (system $command) &&  die "Error: $command\nError converting to msf.";

	    # restrict to query 
	    print "\t\trestrict \n";
	    $command = $path{"restrict_msf_to_query"}. " tmp.msf $query";
	    (system $command) &&  die "Error: $command\nError restricting to query.";  

	    # remove identical again
	    print "\t\tremove identical \n";
	    $command = $path{"remove_id_from_msf"}. " tmp.sifted.msf $query 0.991 > tmp.sifted.pruned.msf";
	    (system $command) &&  die "Error: $command\nError removing identical.";  

	    # remove fragments 
	    print "\t\tremove fragments \n";
	    $command = $path{"remove_fragments"}." tmp.sifted.pruned.msf $query 0.75 > tmp.msf ";
	    (system $command) &&  die "Error: $command\nError removing fragments.";  

	    # if model find alignment btw structure and the whole $name.msf, using the provided alignment
	    if ( defined $options{"MODEL"} ) {
		
		print "\t\talign model structure with the rest of the seqs \n";
	        # (1) cook up an msf consisting of a single, model pdb sequence
		$command = "grep -v $id ". $options{"MODEL_ALMT"}. " > tmp1.msf";
		(system $command) &&  die "Error: $command\nError";  
		$command = $path{"restrict_msf_to_query"}. " tmp1.msf  $name ";
		(system $command) &&  die "Error: $command\nError";  
		# (2) align the structure with the rest of the seqs which came from blast
		$command = $path{"align_by_template"}."  ". $options{"MODEL_ALMT"}.  "  tmp.msf  tmp1.sifted.msf > tmp2.msf";
		(system $command) &&  die "Error: $command\nError";  
		# (3) restrict this alignment to $name
		$command = $path{"restrict_msf_to_query"}. " tmp2.msf  $name ";
		(system $command) &&  die "Error: $command\nError";  
		# (4) remove identical (because now that we have restricted, new things become identical and fragments)
		print "\t\tremove identical \n";
		`echo $name > tmp.names; echo $id >> tmp.names`;
		$command = $path{"remove_id_from_msf"}. " tmp2.sifted.msf tmp.names 0.991 > tmp2.sifted.pruned.msf";
		(system $command) &&  die "Error: $command\nError removing identical.";  
		# (5) remove fragments
		print "\t\tremove fragments \n";
		$command = $path{"remove_fragments"}." tmp2.sifted.pruned.msf $query 0.75 > tmp.msf ";
		(system $command) &&  die "Error: $command\nError removing fragments.";  

		`rm tmp1.msf tmp1.sifted.msf tmp2.msf tmp2.sifted.msf tmp2.sifted.pruned.msf`;
	    }

	    if ( ! -e "$name.mc.ranks" ) {
		print "\t\trunning simulation \n";
		$command = $path{"etc"}." -p tmp.msf -x $name  $name.pdb -c -mc 10 ";
		(defined $options{"MODEL"}) && ( $command .= " -skip_query"); 
		$command .= " -o $name.mc  >& /dev/null";
		#print "$command \n" && exit;
		(system $command) &&  die "Error: $command\nError running etc.";
	    }
	    # postprocess the simulation results
	    # if no seqs are selected - which may happen for small proteins
	    # throw in the towell and move on
	    @aux = split " " , `wc -l $name.mc.best.*.names`;
	    $aux[0] || return "";

	    $cmd_file = prepare_mc_postprocessor ("tmp.msf", "$name.mc", $name, $name, "$name.pdb");
	    $command = $path{"mc_postprocess"}." $cmd_file ";
	    $ret = `$command | grep choosing`;
	    print "\t", $ret;
	    @aux = split " ", $ret;
	    $names_choice = $aux[3];	    
	    $command = $path{"extract_from_msf"}." $names_choice tmp.msf > $name.msf";
	    (system $command) && die "Error: Error extracting seq from msf.";

	    # names file
	    ( -e "$name.names") && `rm $name.names`;
	    `ln -s $names_choice $name.names`;


	    
	} else {
	    # the "best" selection must be named $name.msf
	    if (! -e "$name.msf" ||  `diff  $name.msf $name.hssp.msf`) {
		( -e "$name.msf") && `rm $name.msf`;
		`ln -s $name.hssp.msf $name.msf`;
	    }
	    ( -e "$name.names") && `rm $name.names`;
	    `ln -s $name.hssp.names $name.names`;

	    $is_hssp{"$name.msf"} = 1;
	}
    } else {
	( ! `diff $name.hssp.msf $name.msf` ) && ( $is_hssp{"$name.msf"} = 1);
    }

    $structure = 1;
    return run_ET($name, $name, "$name.msf", "skip query"); 
}

################################################
sub structure_match () {

    my ($coverage, $ret);
    my $not_enough_seqs_flag = 0;

    printf "\tin structure_match\n";

    if ( defined $options{"MODEL"} ) {

	printf "\t\t processing model alignment ...\n";
	$coverage = process_model_alignment ($options{"MODEL_ALMT"});
	$coverage || failure_handle ( "model with no coverage (?)");

    } else {

	my $blastout;
	$blastout =  "$id.pdb.blastp";
	(-e $blastout) || do_blast ($sequence{$id}, $id,  $path{"pdbseq"}, $path{"blast"}, 8,  $blastout);

	if ( ! -s $blastout ) {
	    print "\t\tno matches in pdb\n";
	    $coverage =  0;
	} else {  
	    $coverage =  parse_blast_8_on_pdb (length $sequence{$id}, $blastout);  
	} 
    }
    if ( $coverage )    {
	if (  $coverage < 0.9 ) {
	    $ret =  seq_selection_by_bitval ();
	    printf "emitting from structure_match\n";
	    if ( $ret  ) {
		emit ("$id.tex", $ret);
	    } else { # not enough seqs
		$not_enough_seqs_flag = 1;
		emit ( "$id.tex", not_enough_seqs_blurb ($id) );
	    }
	}
	# proces all chains
	$ret = extract_pdb_chains();
	( $not_enough_seqs_flag && !$ret ) &&  failure_handle ("not enough sequences for any of the chains");
	# intro fig
	( $is_hi_id{$unique_chains[0]} ) && pdb_intro_fig ($unique_chains[0]);
    } else {
	$ret =  seq_selection_by_bitval ();
	#$ret || return $ret;
	#emit ("$id.tex", $ret);
	return $ret;
    }
    
    return "ok";
} 

################################################
sub uniprot_description ( @ ) { 

    my ($filename, $chain, $descriptor, $pct_identity) = @_;
    my $ret;
    printf "\tin description for $chain (id is $id)\n";


    if ( $id_type eq "UNIPROT" ){ 
	if ( !$structure ) {
	    emit ("intro.tex", uniprot_intro_text (@_));
	    $ret = structure_match ();
	    $structure = 0; # structure is global
	    return $ret;
	} else {
	    pdb_uniprot_compare ($chain, $descriptor);
	    ($is_hi_id{$chain}) ||  return uniprot_intro_text (@_);
	}
    } else {
	return uniprot_intro_text (@_);
    }

    return "ok";


}



################################################
################################################
################################################
################################################
################################################

sub determine_id_type () {

    my $ret;
    my $pdbname;
    my $uniprot_entry;
    my ($id2, $id3);


    # check if pdb 
    $id2 = lc $id;
    $ret = `grep $id2  $path{"pdbids"}` || "";
    if ( $ret ) {
	print "\t the id $id is PDB.\n";
	# obtain PDB
	$id = $id2;
	$pdbname = $id;
	pdb_download ($pdbname, $path {"pdb_repository"});
	$pdb_entry{$pdbname} = `cat  $path{"pdb_repository"}/$pdbname.pdb`;
	return ( "PDB", $pdb_entry{$pdbname} );

    }

    # check if uniprot
    $id3 = uc $id;
    $uniprot_entry = `$path{"db_ret"}  $path{"uniprot"}  $id3` || "";
    if ( $uniprot_entry  &&  $uniprot_entry !~ /not found/ ) {
	print "\t the id $id is UNIPROT.\n";
	$id = $id3;
	return ( "UNIPROT", $uniprot_entry);

    }
   
    failure_handle "Unrecognized identifier: $id";
}



#######################################################################################
#
#    MAKE OUTPACKAGE
#
#######################################################################################
sub wrap_up () {

    my ($out, $command);
    my ($attachment, $date, @aux, $zipname);
    my ($fh, $file, $descr);
    print "preparing the outpackage ...\n";

    chdir "texfiles";
    `dvips -Ppdf -G0 $id\_report.dvi -o $id\_report.ps`; 
    `ps2pdf  $id\_report.ps $id\_report.pdf`;
    #`xpdf $id\_report.pdf &`; exit (0);
    chdir "$home";
   
    # tar all intersting files (zip  if the win option is given)
    $out ="$id\_report";
    if ( -e "$home/$out" ) {
	`rm -rf  $home/$out`;
    }
    `mkdir $home/$out`;

    $command = "cp texfiles/$id\_report.pdf  $home/$out";
    (system $command) && die "Error: File copying failure while preparing $out.";



    $command = "cp";
    foreach $attachment ( @attachments ) {
       $command .= " ".$attachment;
    }
    $command .= "  $home/$out";
    (system $command) &&  die "Error: File copying failure while preparing $out.";

    # make README file
    $file = "README";
    $fh = outopen ($file);
    print $fh "\n  This directory ($out) should contain the following files:\n";
    printf $fh "%30s  --  %-100s\n", "$id\_report.pdf", "the report in pdf format";
    foreach $attachment ( @attachments ) {
	$attachment =~ s/\\//g;
	$descr = $attachment_description{$attachment};
	( $descr =~ /Pymol script/ ) && ($descr ="Pymol script"); # I don't know the figure number here
	printf $fh "%30s  --  %-100s\n", $attachment, $descr;   
    }
    $fh->close;
    $command = "unix2dos $file";
    (system $command) && die "Error: unix2dos conversion failure.";
    $command = "mv  $file $home/$out";
    (system $command) &&  die "Error: File copying failure while preparing $out.";
    


    if ( 1 ) {
	print "the package will include unix2dos converted files\n";
	chdir "$home/$out";
	foreach $attachment ( @attachments ) {
	    next if ( $attachment =~ /\Z\.ps/);
	    next if ( $attachment =~ /\Z\.eps/);
	    next if ( $attachment =~ /\Z\.pdf/);
	    $command = "unix2dos $attachment";
	    (system $command) && die "Error: unix2dos conversion failure.";
	}
	chdir "$home";
    }   
    $date = `date`;
    chop $date;
    @aux = split " ", $date;
    $date = $aux[1].$aux[2].".".substr(pop @aux, 2,2 );
    $zipname = $id.".zip";
    ( -e  $zipname )  && `rm $zipname`;
    $command = "zip -r  $zipname $out";
    (system $command) &&  die "Error: Failure zipping the  $out.";
    `rm -rf $out`;
    print "                        ... done\n";

}

