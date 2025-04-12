#! /usr/bin/perl -w
use  DB_File; # Bekeley database stuff
use IO::Handle;         #autoflush
use Math::Trig; # trig functions and number pi
# FH -> autoflush(1);

#######################################################################################
#
#    FUNCTIONS DECLARED AT THE BOTTOM
#
#######################################################################################
sub clust_size (@ );
sub find_plural ( @);
sub four_side_postscript (@);
sub if_subsection (@);
sub help_file();
sub make_rasmol_if ( @ );
sub matching_if_clusters (@);
sub modification_time (@);
sub mutation_table (@);
sub mutation_table_surf (@);
sub orient_pdb (@);
sub percent (@);
sub process_uniprot();
sub process_nr();
sub rasmol_cluster (@);
sub set_colors();
sub species();
sub surf_clusters (@); 
sub table_header (@);
sub table_tail ();
sub this_and_that ( @) ;
 
#######################################################################################
#
#    CHECK FOR DEPENDENCIES
#
#######################################################################################
( defined $ARGV[0] ) ||
    die "\nUsage: report_maker.pl <pdb_name> [-win] [-cdist <distance>] [-cvg <%cvg>] .\nTo read help file, type: report_maker.pl help.\n\n";
if ( $ARGV[0] eq "help" ) {
    help_file ();
    exit 0;
}
$pdbname = $ARGV[0];
$win = 0;
$etv = 0;
$geom_epitope_cutoff_dist = "";
$top_percentage = 25;
foreach $argctr ( 1 .. $#ARGV ) {
    ($ARGV[$argctr]  eq "-win")   && ($win = 1);
    ($ARGV[$argctr]  eq "-cdist") && ($geom_epitope_cutoff_dist  = $ARGV[$argctr+1]);
    ($ARGV[$argctr]  eq "-cvg")   && ($top_percentage = $ARGV[$argctr+1]);
    ($ARGV[$argctr]  eq "-etv")   && ($etv = 1);
}

#constants
$database = "nr";
#$database = "uniprot";
$evalue     =  1.e-5;
$max_gaps       = 0.3;
$max_cvg        = $top_percentage/100;
$CUTOFF_SURF_CLUSTER = 5;

# paths: perlscripts, blast, clustalw, alistat, dssp, etc, latex
$HOME = "/home/i/imihalek";
$home = `pwd`; chomp $home;

if ( $database eq "nr" ) {
    $path{"database"}            = "/home/pine/databases/nr";
    $path{"fastacmd"}            = "$HOME/bin/blast/fastacmd";
    $path{"fasta_names_shorten"} = "$HOME/perlscr/fasta_manip/fasta_names_shorten.pl";
} elsif  ($database eq "uniprot" ) {
    $path{"database"}          = "/home/pine/databases/uniprot";
} else {
    die "Unrecognized database $database.\n";
}

$path{"alistat"}           = "/home/protean2/current_version/bin/linux/alistat";
$path{"blast"}             = "$HOME/bin/blast/blastall";
$path{"clustalw"}          = "/home/protean2/LSETtools/bin/linux/clustalw";
$path{"cluster2tex"}       = "$HOME/perlscr/report_maker/old/cluster2textable.pl";
$path{"CoDing"}            = "/home/pine/databases/cds_dbm/cds_rekeyed.dat";
$path{"color_by_cluster"}  = "$HOME/perlscr/pdb_manip/cbc_for_rasmol.pl";
$path{"color_by_coverage"} = "$HOME/perlscr/pdb_manip/cbcvg_for_rasmol.pl";
$path{"if_cont"}           = "$HOME/c-utils/if_cont"; 
$path{"dssp"}              = "/home/protean2/current_version/bin/linux//dssp"; 
$path{"etc"}               = "$HOME/code/etc/etc";
$path{"extract_clusters"}  = "$HOME/perlscr/pdb_manip/extract_clusters.pl";   
$path{"extract_descr"}     = "$HOME/perlscr/var_ID_descr.pl"; 
$path{"hssp_download"}     = "$HOME/perlscr/downloading/hsspdownload.pl"; 
$path{"hssp2msf"}          = "$HOME/perlscr/translation/hssp2msf.pl"; 
$path{"fasta_cleanup"}     = "$HOME/perlscr/fasta_manip/cleanup_fasta.pl"; 
$path{"find_ligands"}      = "$HOME/perlscr/pdb_manip/find_ligands.pl"; 
$path{"geom_epitope"}      = "$HOME/c-utils/geom_epitope"; 
$path{"geom_center"}       = "$HOME/perlscr/pdb_manip/geom_center.pl"; 
$path{"pdb_cluster"}       = "$HOME/c-utils/pdb_clust/pc"; 
$path{"pdb_download"}      = "$HOME/perlscr/downloading/pdbdownload.pl"; 
$path{"pdb_parse"}         = "$HOME/perlscr/pdb_manip/pdbparse.pl"; 
$path{"pdb_point_place"}   = "$HOME/perlscr/pdb_manip/pdb_point_place.pl"; 
$path{"serial_etc"}        = "$HOME/perlscr/serial_etc.pl";
$path{"serial_etc_for_hssp"} = "$HOME/perlscr/serial_etc_for_hssp.pl";
$path{"rasmol"}            = "$HOME/bin/rasmol"; 
$path{"slab"}              = "$HOME/perlscr/pdb_manip/slab_plane.pl"; 
$path{"suggest"}           = "$HOME/perlscr/suggest_mutations.pl"; 
$path{"texfiles"}          = "$HOME/perlscr/report_maker/old";

# check if all paths ok
foreach $program ( keys %path) {
    ( -e $path{$program} ) || die "$path{$program} not found.\n";
}
print "paths OK.\n";
 
# initialize the db
#%database = ();
#($db = tie %database, 'DB_File', $path{"CoDing"}, O_RDWR, 0444)
#    || die "cannot open database: $!.\n";
#$fd = $db->fd();
#open DATAFILE, "+<&=$fd"
#    ||  die "Cannot open datafile: $!.\n";

# check if all tex files ok, and copy them if found
# find  description or make an empty file and issue a warning
( -e "texfiles" ) || `mkdir texfiles`;
 
@texfiles = ( "header.tex", "notes.tex", "appendix.tex", "tailer.tex" );
@pics = ("colorbar.eps");
foreach $file ( @texfiles, @pics ) {
    (  -e "texfiles/$file" ) || `cp $path{"texfiles"}/$file texfiles`;
    (  -e "texfiles/$file" ) || die "Error locating/opying $file.\n";
} 
print "tex files and pic   OK.\n";
@texfiles = (); # reorganize
push @texfiles, "header.tex";
( -e "texfiles/intro_fig.tex" )  && ( push @texfiles,  "intro_fig.tex");
( -e "texfiles/descr.tex" )  && ( push @texfiles,  "descr.tex");
push @texfiles, "notes.tex";
#             the rest of the sections will be pushed on as they are created

@attachments = (); # keep track of things which need to be attached
%attachment_description = (); 

##### if the author is not known, try to find out
$ret = "" || `grep AUTHORNAME texfiles/header.tex`;
if ( $ret ) {
    print "looking for the username ...\n";
    $username = "";
    $ret = "" || `whoami`;
    if ( $ret ) {
	chomp $ret;
	$ret = "" || `finger $ret | grep Name`;
	if ( $ret ) {
	    chomp $ret;
	    @aux = split ':', $ret;
	    $username =  $aux[2];
	}
	print "$username \n";
    }
  
    if ($username)  {
	$command = "sed \'s/AUTHORNAME/$username"."/\' texfiles/header.tex > tmp";
	print $command;
	( system $command ) && "die sed failure\n";
	`mv tmp texfiles/header.tex`;
    } else { 
	warn "Could not find username.\n";
    }
}


#######################################################################################
#
#    PDB DOWNLOAD AND PARSING
#
#######################################################################################
# find pdb or download pdb 
if ( (!  -e "pdbfiles" )    ||  (! -e "pdbfiles/$pdbname.pdb")  ) { 
    print "downloading $pdbname .. \n"; 
    `echo $pdbname > pdbnames`;  
    $ret = `$path{"pdb_download"}`; 
    print $ret; 
    if ( $ret =~ /failure/ ) {  
	exit;  
    }  
} else {
    print "$pdbname  found in pdbfiles directory.\n";
}
 

# parse PDB
if ( modification_time ( "$pdbname/toc" ) <  modification_time ( "pdbfiles/$pdbname.pdb" ) ){
    print "parsing $pdbname .. \n"; 
    ( -e "pdbnames" ) || `echo $pdbname > pdbnames`;
    $commandline =  $path{"pdb_parse"}." pdbnames";
    $ret  = `$commandline | grep failure`;
    ( -e "failures" ) && die " $ret\n"; #parser produces failure file
    ( -e "successes" ) && `rm successes`; # clean up parser's junk
}



# check for the existence of list of nonphysiological residues
$file =  "nonphys";
if ( -e $file ) {
    open  (IF, "<$file") || die "Cno file.\n";
    while ( <IF> ) {
	chomp;
	$nonphysiological{$_} = 1;
    }
    close IF;
 
}

# pdbparser produced new directory for all of the junk

$no_chains = 0;
@chains = ();
@chain_names = ();
@chain_length = ();
@ligands = ();
@dnas = ();
@rnas = ();
$processed_dna = 0;
$dna_dir = "";
$rna_dir = "";
$ligand_dir = "";


open  (IF, "<$pdbname/toc") || die "Cno toc.\n";
while ( <IF> ) {
    next if ( ! /\S/ );
    chomp;
    if ( /^chain/ ) {
	chomp;
	/chain:\s+([\w\s])\s+length:\s+(\d+)\s+identical_chains:([\w\s\.\d]+)/;
	$chain  =  $1; 
	$length =  $2;
	if ( defined $3 ) {
	    $id_chains = $3;
	} else {
	    $id_chains = "";
	}

	$chain =~ s/\s//g; 
	push @chains, $pdbname.$chain;
	$chain_names{$pdbname.$chain} = $chain ;
	$chain_length{$pdbname.$chain} = $length;
	@{ $identical_chains{$pdbname.$chain} } = ();
	next if ( ! $id_chains );
	foreach $chain2 ( split " ", $id_chains ) {
	    push @{ $identical_chains{$pdbname.$chain} },  $pdbname.$chain2;
	    $chain_names{$pdbname.$chain2} = $chain2 ;
	}
    } elsif ( /^ligand/ ) {
	$ligand_dir =  $pdbname."_ligand";
	/ligand:\s+(\d+)\s+chain:\s+([\w\s])\s+hetnam:\s+(\w+)\s+chem_name:\s+([\w\d\,\-\'\s\+]+)\s+synonyms:([\w\s]+)/;
	$ligand  = $1; 
	$chain   = $2;
	$hetnam  = $3;
	next if ( $nonphysiological{$hetnam} );
	$chem    = $4;  
	$syn     = $5;  
	$ligand  =~ s/\s//g;
	$chain   =~ s/\s//g;
	$chem    =~ s/\s+/ /g;
	#get rid of the last space:
	$last_char = chop $chem; ( $last_char !~ /\s/ ) && ($chem.= $last_char);
	$syn =~ s/\s+/ /g;
	$ligand .= $chain;
	$chain_associated {$ligand} = $chain;
	$hetname{$ligand} = $hetnam;
	( defined $unique_hetnames{$hetnam} ) ||  ( $unique_hetnames{$hetnam} = 1);
	$chem_name{$hetnam} = $chem;
	#$synonyms {$ligand} = $syn; 
	push @ligands, $ligand;

    } elsif ( /^DNA/ ) {
	next if ( $processed_dna );
	$dna_dir = $pdbname."_dna";
	#concatenate pairs of dna strands and treat them as a single ligand
	@pairs = ();
	$file = "$pdbname/$dna_dir/pairs";
	open (IF2, "<$file" ) || die "Failure reading $file: $!.";
	while ( <IF2> ) {
	    chomp;
	    push @pairs, $_;
	    
	}
	close IF2;
	chdir "$pdbname/$dna_dir";
	foreach $pair ( @pairs) {
	    print "$pair\n";
	    ($i, $j) = split " ", $pair;
	    $name1   =  $pdbname.$i.".pdb";
	    $name2   =  $pdbname.$j.".pdb";
	    $dna_name = $pdbname.$i.$j;
	    $commandline =  "cat  $name1 $name2 >  $dna_name.pdb";
	    ( system  $commandline ) &&  die "Error concatenating  $name1 $name2 \n";
	    push @dnas, $dna_name;
	}
	chdir "$pdbname";
	$processed_dna  = 1;

    } elsif  ( /^RNA/ ) {
	$rna_dir = $pdbname."_rna";
	/RNA:\s+([\w\s]+)/;
	$rna_name = $pdbname.$1;
	push @rnas, $rna_name;
    }
}

$no_chains = $#chains + 1;
$plural = "";
( $no_chains != 1 ) &&  ($plural = "s");
print "found $no_chains chain$plural:\n";
$short_count = 0;
foreach $chain ( @chains ) {
    
    print "chain  $chain  length  $chain_length{$chain}    ";
    ( @{ $identical_chains{$chain} } )  &&  print "identical: @{$identical_chains{$chain}}";
    print "\n";
    
    if ( $chain_length{$chain} < 100 ) {
	$too_short{ $chain} = 1;
	$short_count ++;
    } else {
	$too_short{ $chain} = 0;
    }
}

# CHECKPOINT 1: chain length
if ( $short_count == $no_chains ) {
    print "All chains are too short to permit any reasonable analysis.\n";
    exit;
} 

$no_dna = $#dnas + 1;
if ( $no_dna) {
    $plural = "";
    ( $no_dna != 1 ) &&  ($plural = "s");
    print "found $no_dna dna  chain$plural:\n";
    foreach $chain ( @dnas ) {
	print "chain  $chain \n";
    }
}

$no_rna = $#rnas + 1;
if ( $no_rna) {
    $plural = "";
    ( $no_rna != 1 ) &&  ($plural = "s");
    print "found $no_rna rna  chain$plural:\n";
    foreach $chain ( @rnas ) {
	print "chain  $chain \n";
    }
}

$no_ligands = $#ligands + 1;
if ( $no_ligands) {
    $plural = "";
    ( $no_ligands != 1 ) &&  ($plural = "s");
    print "found $no_ligands ligand$plural:\n";
    foreach $ligand ( @ligands ) {
	print "$ligand      $hetname{$ligand}    $chem_name{$hetname{$ligand}} \n";
    }
}


# read in annotation available in pdb,  if any
$file  = "$home/$pdbname/pdb_annotation";
if ( -e $file && -s $file ) {
    open  (IF, "<$file") || die "Cno $file.\n";
    while ( <IF> ) {
	/residue:\s+(\d\w+)\s+chain:\s+([\w\s])\s+annotation:\s+([\w\d\,\-\'\s]+)/;
	$res      = $1; 
	$chain_id = $2;
	$ann      = $3;
	$chain_id =~ s/\s//g;
	$ann      =~ s/\s+/ /g;
	$chain    = $pdbname.$chain_id;
	$annotation{$chain}{$res} = $ann;
    }
    close IF;
 
}

#######################################################################################
#
#    FIGURE FOR THE INTRO
#
#######################################################################################

set_colors ();

if ( modification_time ("texfiles/intro_fig.ps" ) <  modification_time ("$pdbname/toc" ) ) {
    chdir "$home/$pdbname"; 
    # assemble chains from scratch, in case symmetry related parts were reconstructed
    `touch tmp.pdb`;
    foreach $chain ( @chains ) {
	$command = "cat $chain/$chain.pdb >> tmp.pdb";
	(system $command ) && die "Failure concatenating chains for intro ps.\n"; 
	foreach $chain2 ( @{ $identical_chains{$chain} } ) {
	    $command = "cat $chain"."_identical_chains/$chain2.pdb >> tmp.pdb";
	    (system $command ) && die "Failure concatenating chains for intro ps.\n"; 
	}
    }
    # rasmol postscript
    ($no_atoms) = split ' ', `wc -l tmp.pdb`;
    if ( $no_atoms < 10000 ) {
	$rasmol  = "load tmp.pdb\n background white\n restrict protein\n wireframe off\n  cartoons\n";
    } else {
	$rasmol  = " background white\n load tmp.pdb\n restrict protein\n spacefill\n";
    }
    foreach $chain ( @chains ) {
	$letter = $chain_names{$chain};
	$rasmol .= "select :$letter\n color $color{$letter}\n";
	foreach $chain2 ( @{ $identical_chains{$chain} } ) {
	    next if ( $chain2 =~ /\./ ); # this was constructed from biomt
	    $letter = substr $chain_names{$chain2}, 0, 1;
	    $rasmol .= "select :$letter\n color $color{$letter}\n";
	}
    } 
    $rasmol .= "write ps \"intro_fig.ps\"\n quit\n";
    $file  = "tmp.rs"; 
    open  (OF, ">$file") || die "Cno $file.\n";
    print OF $rasmol; 
    close OF; 
    $command = $path{"rasmol"}." < tmp.rs > /dev/null";
    (system $command ) && die "Rasmol failure.\n";  

    $command = "mv intro_fig.ps $home/texfiles";  
    (system $command ) && die "Failure moving intro figure to texfiles.\n"; 
    `rm tmp.pdb tmp.rs`; 
}

    # tex 
    $intr_fig_tex   = "";
    $intr_fig_tex  .= "\\begin\{figure\} [t] \{\n";
    $intr_fig_tex  .= " \\epsfig\{file=intro_fig.ps,   width=0.7\\linewidth\}\n";
    if ( @chains > 1 ) {
	$intr_fig_tex  .= " \}\n \\caption\{\\label\{introfig\} Protein $pdbname, colored by chain. Colors: ";
	foreach $chain ( @chains ) {
	    $letter = $chain_names{$chain};
	    push @aux, "$letter $color_descr{$letter}";
	    foreach $chain2 ( @{ $identical_chains{$chain} } ) {
		next if ( $chain2 =~ /\./ ); # this was constructed from biomt
		$letter =substr $chain_names{$chain2}, 0, 1;
		push @aux, "$chain_names{$chain2} $color_descr{$letter}";
	    }
	} 
    } else {
	$intr_fig_tex  .= " \}\n \\caption\{\\label\{introfig\} Protein $pdbname.";
    }
    $intr_fig_tex  .=    this_and_that ( @aux ).".";
    $intr_fig_tex  .= " \}\n \\end\{figure\}\n";


    $file  = "$home/texfiles/intro_fig.tex"; 
    open  (OF, ">$file") || die "Cno $file.\n";
    print OF $intr_fig_tex; 
    close OF; 

    $file = pop @texfiles; # thats notes
    push @texfiles,  $file;




#######################################################################################
#
#    DESCRIPTION STRING FOR PDB AND MSF 
#
#######################################################################################
chdir $home;

$plural = ""; ($no_chains - $short_count > 1 ) && ( $plural = "s");
$pdb_msf_descr_string  = "\\section\{$pdbname structure and multiple sequence alignment$plural";
$pdb_msf_descr_string .= "\}\n";
$pdb_msf_descr_string .= "\\subsection\{$pdbname  structure file\}\n";
$plural = ""; ($no_chains  > 1 ) && ( $plural = "s");
$pdb_msf_descr_string .= "$pdbname.pdb contains $no_chains unique chain$plural: ";
$first = 1;
$last = $chains [$#chains];
foreach $chain ( @chains ) {
    if ( $first) {
	$first = 0;
    } else {
	$pdb_msf_descr_string .= ", ";
	( $chain eq $last) &&  ($pdb_msf_descr_string .= "and");
    }
    $pdb_msf_descr_string .= " $chain of length  $chain_length{$chain}";
    ( $too_short{$chain} ) &&  ($pdb_msf_descr_string .= "  - too short for ET analysis");
    if ( @{ $identical_chains{$chain} } ) {
	($plural, $is_are) = find_plural( @{ $identical_chains{$chain}} );
	$pdb_msf_descr_string .= " (identical chain$plural: ";
	$pdb_msf_descr_string .= this_and_that ( @{ $identical_chains{$chain}} ).")";
    }
}
$pdb_msf_descr_string .= ". ";
if ( @dnas  ) {
    ($plural, $is_are) = find_plural( @dnas );
    $pdb_msf_descr_string .= "$pdbname.pdb also contains the following DNA molecule$plural: ";
    $pdb_msf_descr_string .= this_and_that ( @dnas ).".\n";
}
if ( @rnas  ) {
    ($plural, $is_are) = find_plural( @rnas );
    $pdb_msf_descr_string .= "$pdbname.pdb also contains the following RNA molecule$plural: ";
    $pdb_msf_descr_string .= this_and_that ( @dnas ).".\n";
}
if ( @ligands  ) {
    ($plural, $is_are) = find_plural( keys %unique_hetnames );
    $pdb_msf_descr_string .= "Furthermore, the following ligand$plural $is_are present: ";
    @aux = ();
    foreach $hetnam (keys %unique_hetnames ) {
	push @aux, $hetnam. " (". lc $chem_name{$hetnam}.")";
    }
    $pdb_msf_descr_string .= this_and_that ( @aux ).".\n";
}
if ( %nonphysiological ) {
    ($plural, $is_are) = find_plural( keys %nonphysiological );
    $pdb_msf_descr_string .= "(The following ligand$plural $is_are deemed nophysiological: ";
    $pdb_msf_descr_string .= this_and_that  ( keys %nonphysiological ).".)\n";

}


#######################################################################################
#
#    HSSP  DOWNLOAD
#
#######################################################################################
chdir $home;
(-e "hsspfiles/$pdbname.hssp") || system $path{"hssp_download"};
$hssp_ok = (-e "hsspfiles/$pdbname.hssp"  &&  -s "hsspfiles/$pdbname.hssp");
if ( $hssp_ok ) {
    # extract chains for individual hssp
    chdir "hsspfiles";
    foreach $chain ( @chains) {
	if (  ! -e "../$pdbname/$chain/$chain.hssp.msf" ) {
	    $command = $path{"hssp2msf"}." $pdbname.hssp  $chain_names{$chain} > ../$pdbname/$chain/$chain.hssp.msf";
	    (system $command ) && die "hssp2msf failure.\n"; 	
	}    
    }
} else {
    warn "hssp download failure\n";
}



#######################################################################################
#
#    BLAST,  MULTIPLE SEQUENCE ALIGNMENTS, ETC
#
#######################################################################################

# for each chain:  - CHECKPOINT: chain length
#                  - assemble info about each residue: surface, interface, ligand, PDB annotation
#                  -  find fasta or blast --> CHECKPOINT: sucess
#                  - rename sequences and make description tables
#                  -  find msf or clustalw--> CHECKPOINT: sucess
#                  - prune 69 (or 85?)--> CHECKPOINT: how many seq, similarity, z-score
#                  - alignment report


chdir $home;

# msf assembly and reporting
foreach $chain ( @chains ) {
    next if ( $too_short{ $chain} );

    $pdb_msf_descr_string .= "\\subsection\{Multiple sequence alignment for $chain \}\n";

    (chdir "$pdbname/$chain") || die "Cannot chdir to $pdbname/$chain: $!.\n" ; 

    print "\nworking on $chain.\n"; 

    ######################################################## 
    # decide where we need to start:
    @usual_levels = ("blast", "fasta",  "raw", "pruned",  "ET", "description" ,); 
    %key_file =  ("blast", "$chain.blastp",  "fasta","$chain.fasta",  "raw", "$chain.raw.msf",  
		  "pruned", "$chain.pruned.msf", "ET", "$chain.ranks", "description", "$chain.pruned.descr" );  

    # first, try to detect the starting level: 
    # for example, if blastp does not exist at all, that means we start from fasta
    # unless, that is, no level exists in which case we start from scratch
    # - in other words, if you want to start from scratch, clean up the directory
    @levels = @usual_levels;
    foreach  $level ( @usual_levels ) {
	$redo{$level} = 0;
    }
  

    while ( $level = shift @levels ) {
	if ( -e $key_file{$level} ) {
	    unshift @levels, $level;
	    last;
	} 
    }
    print "levels:  @levels\n\n";

    if ( @levels ) {
	foreach  $level ( @levels ) {
	    $time_changed{$level} = modification_time ($key_file{$level});
	}
	
	for ( $level_ctr =1; $level_ctr <= $#levels; $level_ctr++) {
	    if ( $redo{$levels[$level_ctr-1]}  || 
		 $time_changed{$levels[$level_ctr-1]} >  $time_changed{$levels[$level_ctr]} ) {
		print" $levels[$level_ctr]     $time_changed{$levels[$level_ctr]}  ";
		print"  $levels[$level_ctr-1]  $time_changed{$levels[$level_ctr-1]} \n";
		$redo{$levels[$level_ctr]} = 1;
		
	    }
	}

    } else {
	@levels = @usual_levels;
	foreach  $level ( @usual_levels ) {
	    $redo{$level} = 1;
	}
    }


    foreach  $level ( @levels ) {
	printf "\t %15s   redo: %1d \n", $level,  $redo{$level};
    }

    ########################################################
    #blast
    if ( $redo{"blast" } ) {
	$query = $chain.".seq";
	print "\t running blast, E-value is set to $evalue ... \n"; 
	# note: the format has to be -m8, otherwise the thins below won't work
	$commandline = "nice ".$path{"blast"}." -p blastp -d ".$path{"database"}." -i $query -o $chain.blastp -e $evalue -m 8";
	( system ($commandline) ) && die "$chain: blast failure";
	print "\t               ... done \n"; 
 
	if ( $database  eq "uniprot" ) {
	    `awk '{print \$2}' $chain.blastp > $chain.names`;
	} elsif ( $database  eq "nr" ) {
	    `awk -F '\|' '{print \$2}' $chain.blastp > $chain.names`;
	}   
	# CHECKPOINT 2: number od sequences
	$no_seqs = `wc -l  $chain.names | awk '{print \$1}'`; chomp $no_seqs;
	( $no_seqs >=  10 ) || die "$chain: Too few ($no_seqs) sequences  returned from blast.\n";
    }
    

    # fasta
    if ( $redo{"fasta" } ) {

       $fastafile = "$chain.fasta";
       if ( $database eq "nr" ) {
	   process_nr();
       } elsif  ($database eq "uniprot" ) {
	   process_uniprot();
       }
    
       # add the original seq to fasta and clean up
       $ret = `grep $chain  $chain.fasta`; # check if we already have it there by some chance
       ($ret) ||  `cat $chain.seq $chain.fasta > tmp && mv tmp  $chain.fasta`;
       $commandline = $path{"fasta_cleanup"}." $chain.fasta  $chain > $chain.fasta_cleanup.log";
       (system ($commandline)) && die "$chain: fasta cleanup failure"; 

       # CHECKPOINT 3: number od sequences 
       $no_seqs = `grep '>' $chain.fasta | wc -l `; chomp  $no_seqs;
       ( $no_seqs >=  10 ) || die "$chain: Too few ($no_seqs) sequences remained after cleanup.\n";

    }
      

    #align
    if ( $redo{"raw"} ) {
 	print "\t running clustalw... \n"; 
	$commandline = $path{"clustalw"}." -quicktree -output= gcg -infile= $chain.fasta  -outfile= $chain.raw.msf > /dev/null";
        (system ($commandline)) ||  die "$chain: clustalw failure"; # stupid clustalw exits with nonzero on success
	print "\t               ... done \n"; 
    }

    #prune 
    if ( $redo{"pruned"} )  {

	print "\t sequence selection ... \n"; 
	chdir $home;
	`echo $chain > tmp`;
	$commandline = $path{"serial_etc"}." tmp";
        (system ($commandline)) &&  die "$chain: etc failure"; 
	if ( $hssp_ok ) {
	    $commandline = $path{"serial_etc_for_hssp"}." tmp";
	   (system ($commandline)) &&  die "$chain: etc failure"; 
	    
	}
	#find best and link it to $chainname.best.msf
	$max_area    = -10;
	$max_summary = "";
	chdir "$pdbname/$chain";
	@summary_files  = split " ", `ls *summary`;
	foreach $summary_file ( @summary_files ) {
	    $area = `grep area $summary_file | awk '{ print \$2}'`;
	    $area =~ s/\s//g;
	    if ( $area > $max_area ) {
		$max_area    = $area;
		$max_summary = $summary_file;
	    }
	}
	$preferred_pruning = $max_summary;	$preferred_pruning =~ s/\.cluster_report\.summary//;
	( $preferred_pruning =~ "hssp" ) || ( $preferred_pruning .= ".pruned" ); # some naming complications
	( $preferred_pruning =~ "hssp.raw" ) &&  ( $preferred_pruning = "$chain.hssp" );
	( $preferred_pruning =~ "raw" ) &&  ( $preferred_pruning = "$chain.raw" );
	print "preferred pruning $preferred_pruning  with max area  $max_area  \n"; 
	`ln -sf $preferred_pruning.msf $chain.pruned.msf`;

	# CHECKPOINT 4: number od sequences 
	$no_seqs = `grep Name $chain.pruned.msf | wc -l`; chomp  $no_seqs;
	( $no_seqs >=  10 ) || die "$chain: Too few ($no_seqs) sequences remained after pruning.\n";
    }

    # run ET
    if ( $redo{"ET"} )  {
	print "\t running etc ... \n"; 
	$commandline = $path{"etc"}." -p $chain.pruned.msf -o $chain  -c -x $chain $chain.pdb ";
        (system ($commandline)) &&  die "$chain: etc failure\n $commandline\n"; 
	print "\t               ... done \n"; 
    }

    $z_score = `grep max  $chain.cluster_report.summary | sed 's/\%//g' | awk '{print \$2}'`; 
    # several version of etc ....
    ($z_score eq "score") && ( $z_score = `grep max  $chain.cluster_report.summary | sed 's/\%//g' | awk '{print \$3}'`); 
    $area = `grep area  $chain.cluster_report.summary | sed 's/\%//g' | awk '{print \$2}'`; 
    print  "z-score: $z_score\n"; 
    print  "area: $area\n"; 

    # CHECKPOINT 5:the z-score & area
    if ( $redo{"ET"} )  {
	( $area > 2 )  || die "$chain: area  for $chain  only $area"; 
	( $z_score >  4 )  || die "$chain: z-score for $chain  only $z_score"; 
    }

    push @attachments, "$chain.ranks_sorted"; 
    $attachment_description {"$chain.ranks_sorted"} = "ET result for the chain $chain, raw output.\n";
    

    # extract remaining seq names and find their description 
    ( -e "$chain.pruned.names" ) || ( `grep Name $chain.pruned.msf | awk '{print \$2}'  > $chain.pruned.names`); 
    $no_seqs = `wc -l  $chain.pruned.names | awk '{print \$1}'`; chomp $no_seqs;
    ( $no_seqs ) || die "No sequences found in $chain.pruned.msf.\n";
    $pdb_msf_descr_string .= "For the chain $chain, the alignment $chain.pruned.msf (attached) with $no_seqs sequences was used."; 
    push @attachments, "$chain.pruned.msf"; 
    $attachment_description {"$chain.pruned.msf"} = "the multiple sequence alignment used for the chain $chain.\n";

    # alistat	
    $commandline = $path{"alistat"}." $chain.pruned.msf | tail -n 12| head -n 11 ";
    $ret =  `$commandline`;
    ($ret) || die "$chain: alistat failure.";
    $ret =~ s/\#/number of/g;

    $pdb_msf_descr_string .= "Its statistics, using \\emph{alistat} program is the following: ";
    if  (! defined $alistat_footnonte ) {
	$alistat_footnonte = 1;
	$pdb_msf_descr_string .= "\\footnote\{See Appendix for the explanation of the fields  and \\emph{alistat\}'s copyright statement\}:\n";
    } else {
	$pdb_msf_descr_string .= "\n";
    }
    $pdb_msf_descr_string .= "\\begin\{verbatim}\n$ret \n \\end\{verbatim\}\n";


    # sequence description
    if ( -e "$chain.custom.descr" ) {
	( -e  "$chain.pruned.descr" ) && `rm $chain.pruned.descr`;
	`ln -s $chain.custom.descr $chain.pruned.descr`;
    } elsif ( $redo{"description"} ) {
	$commandline = $path{"extract_descr"}." < $chain.pruned.names > $chain.pruned.descr ";
	`$commandline`;
    }
   
    #count species
    species();
    $pdb_msf_descr_string .= "The file containing the sequence descriptions can be found in the attachment.\n";
    push @attachments, "$chain.pruned.descr"; 
    $attachment_description {"$chain.pruned.descr"} = "description of sequences ued in $chain msf.\n";

    #back to the home directory
    chdir "../..";
}

$file = "sec1.tex";
open ( OF, ">texfiles/$file" ) || die "Cno $file: $!.\n"; 
print OF  $pdb_msf_descr_string;
close OF;
push @texfiles, $file;

#######################################################################################
#
#    SURFACE AND INTERAFCE INFO
#
#######################################################################################

chdir $pdbname;

# for the complex; find surface using dssp
if ( ! -e "$pdbname.dssp" ) {
    $ret = `$path{"dssp"}   ../pdbfiles/$pdbname.pdb  $pdbname.dssp`;
    ( -e "$pdbname.dssp") || die "dssp failure.\n";
} else {
    print "$pdbname.dssp found.\n";
}
# read dssp
$file = "$pdbname.dssp";
open (IF, "<$file" ) || die "Cno $file.\n";
while (<IF>) {
    last if (/RESIDUE AA STRUCTURE/);
}
while (<IF>) {
    $residue      = substr $_, 5, 5;  $residue      =~ s/\s//g;
    $chain_name   = substr $_, 11, 1; $chain_name   =~ s/\s//g;
    $accesibility = substr $_, 34, 4; $accesibility =~ s/\s//g;
    ( ! %chain_names ) &&  ( $chain_name = "" );
    $chain = $pdbname.$chain_name;
    $accessible{ $chain}{$residue} = ( $accesibility > 1 );
    foreach $chain2 ( @ { $identical_chains{$chain} } ) {
	$accessible{ $chain2}{$residue} = ( $accesibility > 1 );
    }
}
close IF;

# for each chain
foreach $chain1 ( @chains ) {
    next if ( $too_short{$chain1} );
    chdir "$home/$pdbname/$chain1";
    foreach $chain2 ( @chains ) { # interface with other chains

	foreach $chain3( @{ $identical_chains{$chain2} } ) { # interface with chains homologous to chain2
	    if ( -e  "$chain1.$chain3.geom_epitope" ) {
		print "found $chain1.$chain3.geom_epitope\n";
	    } else {
		print "determining $chain1.$chain3.geom_epitope\n";
		$path = "../$chain2"."_identical_chains";
		$commandline = $path{"geom_epitope"}."  $chain1.pdb $path/$chain3.pdb $geom_epitope_cutoff_dist  > $chain1.$chain3.geom_epitope";
		( system $commandline) &&  die "geom epitope failure.\n";
	    }
	}

	next if ( $chain1 eq $chain2);

	if ( -e  "$chain1.$chain2.geom_epitope" ) {# interface with "main"  chains
	    print "found $chain1.$chain2.geom_epitope\n";
	} else {
	    print "determining $chain1.$chain2.geom_epitope\n";
	    $commandline = $path{"geom_epitope"}."  $chain1.pdb ../$chain2/$chain2.pdb $geom_epitope_cutoff_dist  > $chain1.$chain2.geom_epitope";
	    ( system $commandline) &&  die "geom epitope failure.\n";
	}
    }
    foreach $chain2 (  @ligands ) {# interface with ligands
	if ( -e  "$chain1.$chain2.geom_epitope" ) {
	    print "found $chain1.$chain2.geom_epitope\n";
	} else {
	    print "determining $chain1.$chain2.geom_epitope\n";
	    $dir = "$home/$pdbname/$pdbname"."_ligands";
	    $commandline = $path{"geom_epitope"}."  $chain1.pdb $dir/$pdbname.$chain2.pdb $geom_epitope_cutoff_dist > $chain1.$chain2.geom_epitope";
	    ( system $commandline) &&  die "geom epitope failure.\n";
	}
    }
    foreach $chain2 (  @dnas ) {# interface with dnas
	if ( -e  "$chain1.$chain2.geom_epitope" ) {
	    print "found $chain1.$chain2.geom_epitope\n";
	} else {
	    print "determining $chain1.$chain2.geom_epitope\n";
	    $dir = "$home/$pdbname/$pdbname"."_dna";
	    $commandline = $path{"geom_epitope"}."  $chain1.pdb $dir/$chain2.pdb $geom_epitope_cutoff_dist > $chain1.$chain2.geom_epitope";
	    ( system $commandline) &&  die "geom epitope failure.\n";
	}
    }
    foreach $chain2 (  @rnas ) {# interface with rnas
	if ( -e  "$chain1.$chain2.geom_epitope" ) {
	    print "found $chain1.$chain2.geom_epitope\n";
	} else {
	    print "determining $chain1.$chain2.geom_epitope\n";
	    $dir = "$home/$pdbname/$pdbname"."_rna";
	    $commandline = $path{"geom_epitope"}."  $chain1.pdb $dir/$chain2.pdb $geom_epitope_cutoff_dist > $chain1.$chain2.geom_epitope";
	    ( system $commandline) &&  die "geom epitope failure.\n";
	}
    }
 
}


#######################################################################################
#
#    DISCUSSION OF TOP RANKING RESIDUES - INDIVIDUAL CHAINS
#
#######################################################################################


#
foreach $chain ( @chains ) {
    next if ( $too_short{$chain} );
    chdir"$home/$pdbname/$chain";
    $results_string{$chain}  = "\n\\section\{Top ranking residues in $chain}\n";

    # attach pdbs
    push @attachments, "$chain.pdb";
    $chain_name = "";  ( defined $chain_names{$chain}) && ($chain_name = $chain_names{$chain});
    $attachment_description {"$chain.pdb"} = "Chain $chain_name coordinates extracted from the original $pdbname.pdb file.\n";

    # make rasmol script for color-by-coverage
    if ( modification_time ("$chain.ranks_sorted.rs" ) < modification_time ("$chain.ranks_sorted" ) ) {
	$commandline = $path{"color_by_coverage"}."  $chain.ranks_sorted  $chain.pdb $chain.ranks_sorted.rs";
	( system $commandline) &&  die "cbcvg failure.\n";
    }
    if ( $etv) {
	# make etv file
	`echo $chain >  $chain.etvx`;
	`echo ~pdb   >> $chain.etvx`;
	`cat $chain.pdb   >> $chain.etvx`;
	`echo ~ET_ranks   >> $chain.etvx`;
	`cat $chain.ranks >> $chain.etvx`;
	`echo  ~tree >> $chain.etvx`;
	`cat $chain.pss.nhx >> $chain.etvx`;
	`echo ~z_scores >> $chain.etvx`;
	`cat $chain.cluster_report.summary >> $chain.etvx`;
	push @attachments, "$chain.etvx";
	$attachment_description {"$chain.etvx"} = "input file for ET viewer (ETV)";
    }

    # make postscriptfiles
    if (  modification_time ("$home/texfiles/$chain.front.ps" ) < modification_time ("$chain.ranks_sorted.rs" ) ) {
  	four_side_postscript ( "$chain.ranks_sorted.rs", $chain);
    }

    $results_string{$chain}  .= "Figure \\ref\{cbcvg$chain\} shows residues in $chain colored by their importance:\n";
    $results_string{$chain}  .= "bright red (and yellow) inidicates more conserved/important residues ";
    $results_string{$chain}  .= "(see Appendix for the coloring scheme).";
    $results_string{$chain}  .= "Ramol script for producing this figure can be found in the attachment.\n";
    push @attachments, "$chain.ranks_sorted.rs";
    $attachment_description {"$chain.ranks_sorted.rs" } = "Rasmol script for Fig.\\ref\{cbcvg$chain\}";


    $results_string{$chain}  .= "\\begin\{figure\} [t] \{\n";
    foreach $side ( "front", "back", "top", "bottom" ) {
	$results_string{$chain}  .= " \\epsfig\{file=$chain.$side.ps,   width=0.24\\linewidth\}\n";
    }
    $results_string{$chain}  .= " \}\n \\caption\{\\label\{cbcvg$chain\} Residues in $chain, colored
                     by their relative importance. Front, back, top and bottom view} \n\\end\{figure\}\n";

    # read aa frequencies at each position in the almt
    $file = "$chain.aa_freqs";
    open (IF, "<$file" ) || die "Cno $file.\n";
    while ( <IF> ) {
	next if ( /%/ );
	next if ( !/\S/ );
	chomp;
	@aux = split;
	next if ( $aux[1] eq '.' );
	%{$aa_freqs{$chain}{$aux[2]}} =  @aux[3 .. $#aux];
    }
    close IF;




    # read in residues and coverage
    %type = ();
    %var  = ();
    %subst= ();
    %cvg  = ();
    %gaps = ();
    $alignment_no =$residue =$typ =$rank =$variability =$substitutions = $rho=$coverage = $gapp = 0;
    $file = "$chain.ranks_sorted";
    open (IF, "<$file" ) || die "Cno $file.\n";
    while ( <IF> ) {
	next if ( /%/ );
	next if ( !/\S/ );
	chomp;
	( $alignment_no,  $residue,  $typ,  $rank,  $variability,  $substitutions, $rho, $coverage, $gapp) = split;
	next if ( $residue eq "-" );
	$type{$residue} = $typ;
	$var{$residue}  = $variability;
	$subst{$residue}= $substitutions;
	$cvg{$residue}  = $coverage;
	$gaps{$residue} = $gapp;
	
    }
    close IF;


    # which coverage is the closest to max_cvg?
    $file = "$chain.cluster_report.summary";
    ($rank,  $coverage, $n, $s, $scnd, $z, $cow) = ();
    open (IF, "<$file" ) || die "Cno $file.\n";
    $min_dist = 2.0;
    while ( <IF> ) {
	next if ( /%/ );
	next if ( !/\S/ );
	last if ( /area/);
	chomp;
	($rank, $coverage, $n, $s, $scnd, $z, $cow) = split;
	$dist = abs ($coverage - $max_cvg);
	if ( $min_dist >  $dist ) {
	    $min_dist = $dist;
	    $min_dist_rank = $rank;
	    $min_dist_cvg = $coverage;
	}
    }
    print "$chain: the coverage closest to $max_cvg: $min_dist_cvg (rank $min_dist_rank)\n";


    # plot clusters at that coverage
    if ( modification_time ("$chain.clusters.rank=$min_dist_rank.rs" ) < modification_time ("$chain.clusters" ) ) {
	$commandline = $path{"color_by_cluster"}." $chain.clusters $chain.pdb  $min_dist_rank  ";
	(system $commandline) &&  die "rasmol failure.\n";
   }
	 
    if ( modification_time ("$home/texfiles/$chain.cluster$min_dist_rank.front.ps")  <  
	 modification_time ("$chain.clusters.rank=$min_dist_rank.rs")	 ) {
	four_side_postscript ( "$chain.clusters.rank=$min_dist_rank.rs", "$chain.cluster$min_dist_rank");
    }
    $results_string{$chain}  .= "Fig.\\ref\{cbcluster$chain\} shows the same top $top_percentage\\% residues,";
    $results_string{$chain}  .= "this time colored according to clusters they belong to.\n";
    $results_string{$chain}  .= "\\begin\{figure\} [t] \{\n";
    
    foreach $side ( "front", "back", "top", "bottom" ) {
	$results_string{$chain}  .= " \\epsfig\{file=$chain.cluster$min_dist_rank.$side.ps,   width=0.24\\linewidth\}\n";
    }
    $results_string{$chain}  .= " \}\n \\caption\{\\label\{cbcluster$chain\} Residues in $chain, colored";
    $results_string{$chain}  .= " according to the cluster they belong to Red,followed by blue and yelloe ";
    $results_string{$chain}  .= " are the largest clusters (see Appendix for the coloring scheme).";
    $results_string{$chain}  .= " Front, back, top and bottom view.Rasmol script attached.} \\end\{figure\}\n";
    push @attachments ,  "$chain.clusters.rank=$min_dist_rank.rs";
    $attachment_description {"$chain.clusters.rank=$min_dist_rank.rs"} =  "Rasmol script for Fig.\\ref\{cbcluster$chain\}";

    # find clusters at that coverage - list them in a table
    $commandline = $path{"cluster2tex"}." $chain.clusters  $min_dist_rank  ";
    $ret = `$commandline`;
    $results_string{$chain}  .= "The clusters in Fig.\\ref\{cbcluster$chain\} are comprised of the following residues:\n\\newline\n";
    $results_string{$chain}  .= $ret;

    # find surface clusters for the coverage 
    $dir = "$home/$pdbname/$chain";
    @{ $surf_clust{$chain} }  =  surf_clusters ($chain, $dir); # I'll use it at the chain-chain if too
    #########################################################
    # THIS SHOULD BE CHECKED!!!!!
    # proceed assuming that the identical chains follow the same enumeration as the first one
    # and construct shells
    #########################################################
    foreach $chain2( @{ $identical_chains{$chain} } ) {
	$dir = "$home/$pdbname/$chain"."_identical_chains"; 
	@{ $surf_clust{$chain2} }  =  surf_clusters ($chain2, $dir); # I'll use it at the chain-chain if too
    } 


    # which residues belong to interface(s)? 
    %epi = (); # this will be defined for any residue which belongs to any know interface
    # for each pair of chains - find interface 
    #                  - extract top 25% residues belonging to the interface
    #                  - sugest mutations 
    #                  - make section 
    foreach $chain2 ( @chains ) { 
	next if ( $chain2 eq $chain );   
	$dir2 = $chain2; 
	if_subsection ($chain2); 
    } 
    foreach $chain2 ( @chains ) { # chains identical to one or the other of "main" chains 
	foreach $chain3( @{ $identical_chains{$chain2} } ) { 
	    $dir2 = $chain2."_identical_chains"; 
	    if_subsection ( $chain3 ); 
	}
    } 


    # for each pair of chains- ligand  - 
    #                  - extract top 25% residues belonging to the functional site
    #                  - sugest mutations
    #                  - make section

    foreach $chain2 ( @ligands,  @dnas, @rnas) { if_subsection ( $chain2);  }

    ##########################################################################
    # new interface ?
    ##########################################################################
    # are there clusters not belonging to  any known if?
    @unassigned_clusters = ();
    foreach $cluster (@{ $surf_clust{$chain} }) {
	$ctr = 0; 
	$epi_ctr = 0;
	foreach $residue (split "_", $cluster) {
	    next if ( ! $residue);
	    ( defined $epi{$residue} ) && $epi_ctr++;
	    $ctr ++;
	}
	if ( $ctr && $epi_ctr/$ctr < 0.2 ) {
	    push @unassigned_clusters, $cluster;
	}
    }

    # if anything interesting found, make a subsection about it;
    if ( @unassigned_clusters ) {
	
	chdir "$home/$pdbname/$chain";
	$ret = "" || `$path{"extract_clusters"} $chain.clusters  $min_dist_rank`;
	print $path{"extract_clusters"}." $chain.clusters  $min_dist_rank \n";
	print `pwd`;
	($ret) ||  die "Failure extracting clusters.\n";
	@vol_clust = split '\n', $ret;
	$vc_size = ();
	foreach $vol_cluster  ( @vol_clust )  {
	    $vc_size{ $vol_cluster } = clust_size ( $vol_cluster );
	}

	if ( %chain_names ) {
	    $results_string{$chain}  .= "\n\\subsection\{Other (possible) functional surfaces in $chain}\n\n";
	} else {
	    $results_string{$chain}  .= "\n\\subsection\{Possible functional surfaces in $chain}\n\n";
	}

	$cluster_ctr = 0;
	foreach $cluster (@unassigned_clusters) {


	    $cluster_ctr ++;
	    
	    # make rasmol script and ps
	    if (modification_time ("$home/texfiles/$chain.surfclust$cluster_ctr.ps" )  < modification_time ("$chain.ranks_sorted" ) ) {

		
		# find geom center of the surface cluster
		$file = "tmp";
		open (OF, ">$file" ) || die "Cno $file.\n";
		$file = "$chain.pdb";
		open (IF, "<$file" ) || die "Cno $file.\n";
		while (<IF>) {
		    $residue  = substr $_, 22, 4;  $residue=~ s/\s//g;
		    $string = "_$residue"."_";
		    ( $cluster =~ $string ) &&  print OF;
		}
		close IF;
		close OF;
		$command = $path{"geom_center"}."  tmp"; 
		($x_center, $y_center, $z_center,) = split " ", `$command`;
		# orient pdb so that we look at that point face-on
		print "cluster  $cluster_ctr center: $x_center, $y_center, $z_center\n"; 
		$command = $path{"pdb_point_place"}."  $chain.pdb  $x_center  $y_center  $z_center  > tmp.pdb"; 
		(system `$command`) || die "Failure rotating $pdbname.pdb.\n";


		# make rasmol script
		$rsfile = "$chain.surfclust$cluster_ctr.rs"; 
		$rasmol = "";
		$rasmol .= "load tmp.pdb\n";
		$rasmol .= "background white\n";
		$rasmol .= "spacefill\ncolor white\n"; 

		rasmol_cluster ($cluster, "red");
		open (OF, ">$rsfile" ) || die "Cno $rsfile.\n";
		print OF  $rasmol; 
		close OF; 

		# make postscript
		$instructions  = "write ps \"$chain.surfclust$cluster_ctr.ps\"\n";
		$instructions .= "quit\n";
		open (OF, ">tmp" ) || die "Cno tmp: $!.\n";
		print OF $instructions;
		close OF;
		$commandline = $path{"rasmol"}." -script $rsfile < tmp > /dev/null ";
		( system $commandline) &&  die "rasmol failure.\n";
		`mv $chain.surfclust$cluster_ctr.ps  $home/texfiles`;
		( -e "tmp" ) && (`rm tmp`); 
	    }
	    

	    # relate it back to the overall clusters
	    $cluster_size = clust_size ($cluster);
	    @mother_clusters = ();
	    foreach $vol_cluster ( @vol_clust) {
		$overlap = 0;
		foreach $residue ( split "_", $cluster) {
		    next if (!$residue);
		    $string = "_$residue"."_";
		    ( $vol_cluster =~ $string ) &&  ($overlap ++);
		}
		( $overlap ) && ( push @mother_clusters,  $vol_cluster);
	    }
	    
	    $buried = $belongsto = $same = 0;
	    foreach $vol_cluster ( @mother_clusters) {
		($#mother_clusters <1 ) || die "Surf cluster belonging to several volume clusters ?! ($chain.)\n";
		$diff = $vc_size{$vol_cluster} -  $cluster_size;
		if ( $diff ) {
		    if ( $diff  < 4 ) {
			$buried = 1;
		    } else {
			$belongsto = 1;
		    }
		} else {
		    $same = 1;
		}
	    }		

	    # if this is a part of larger cluster, make a fig to show it
	    if ( $belongsto ) {
		if (  modification_time ("$home/texfiles/$chain.surfclust$cluster_ctr.2.ps" )  < modification_time ("$chain.ranks_sorted" ) ) {

		    $rsfile = "$chain.surfclust$cluster_ctr.2.rs"; 

		    # find geom center of the surface cluster
		    $file = "tmp";
		    open (OF, ">$file" ) || die "Cno $file.\n";
		    $file = "$chain.pdb";
		    open (IF, "<$file" ) || die "Cno $file.\n";
		    while (<IF>) {
			$residue  = substr $_, 22, 4;  $residue=~ s/\s//g;
			$string = "_$residue"."_";
			( $cluster =~ $string ) &&  print OF;
		    }
		    close IF;
		    close OF;
		    $command = $path{"geom_center"}."  tmp"; 
		    ($x_center, $y_center, $z_center,) = split " ", `$command`;

		    # orient pdb so that we look at that point face-on
		    print "cluster  $cluster_ctr center: $x_center, $y_center, $z_center\n"; 
		    $command = $path{"pdb_point_place"}."  $chain.pdb  $x_center  $y_center  $z_center  > tmp.pdb"; 
		    (system `$command`) || die "Failure rotating $chain.pdb.\n";

		    $rasmol = "";
		    $rasmol .= "load tmp.pdb\n";
		    $rasmol .= "wireframe off\n";
		    $rasmol .= "backbone 150\n";
		    $rasmol .= "background white\n";

		    $vol_cluster = $mother_clusters[0];
		    rasmol_cluster ( $vol_cluster, "blue");
		    rasmol_cluster ( $cluster, "red");
		    
		    $ctr = 0;


		    open (OF, ">$rsfile" ) || die "Cno $rsfile.\n";
		    print OF  $rasmol; 
		    close OF; 

		    $instructions  = "write ps \"$chain.surfclust$cluster_ctr.2.ps\"\n";
		    $instructions .= "quit\n";
		    open (OF, ">tmp" ) || die "Cno tmp: $!.\n";
		    print OF $instructions;
		    close OF;
		    $commandline = $path{"rasmol"}." -script $rsfile < tmp > /dev/null ";
		    ( system $commandline) &&  die "rasmol failure.\n";
		    `mv $chain.surfclust$cluster_ctr.2.ps  $home/texfiles`;
		    ( -e "tmp" ) && (`rm tmp`); 
		}
	    }



            #include the figure in the text
	    if ( $cluster_ctr == 1 ) {
		$results_string{$chain}  .= "One group of residues is conserved on the $chain surface, away from other";
		$results_string{$chain}  .= " functional sites and interfaces recognizable in $pdbname.pdb.";
		$results_string{$chain}  .= " It is shown in Fig \\ref{surfclust$cluster_ctr}.";
	    } else {
		$results_string{$chain}  .= " Another group of surface residues is shown in.";
		$results_string{$chain}  .= "  Fig.\\ref{surfclust$cluster_ctr}.";
	    }
	    $results_string{$chain}  .= "The residues belonging to this surface \"patch\" are the following:\n"; 
	    @aux = split "_", $cluster;
	    pop @aux; shift @aux; # the first and the last are empty
	    mutation_table_surf (@aux); 

	    $results_string{$chain}  .= "\\begin\{figure\} [t] \{\n";  
	    $results_string{$chain}  .= " \\epsfig\{file=$chain.surfclust$cluster_ctr.ps,   width=0.4\\linewidth\}\n";
	    ($belongsto) &&   ($results_string{$chain}  .= " \\epsfig\{file=$chain.surfclust$cluster_ctr.2.ps,   width=0.4\\linewidth\}\n");
	    if ( $cluster_ctr == 1 ) {
		$results_string{$chain}  .= " \}\n \\caption\{\\label\{surfclust$cluster_ctr\} A possible active surface on the chain $chain.";
	    } else {
		$results_string{$chain}  .= " \}\n \\caption\{\\label\{surfclust$cluster_ctr\} Another  possible active surface on the chain $chain.";
	    }
	    ($belongsto) &&   ($results_string{$chain}  .= " The right panel shows (in blue) the rest of the larger cluster this surface belongs to.");
	    $results_string{$chain}  .= "\}\n \\end\{figure\}\n";


	}
    } 

    $file = "sec_$chain.tex";
    open ( OF, ">$home/texfiles/$file" ) || die "Cno $file: $!.\n"; 
    print OF  $results_string{$chain};
    close OF;
    push @texfiles, $file;

} 

#######################################################################################
#
#    DISCUSSION OF TOP RANKING RESIDUES - INTERFACES
#
#######################################################################################

# is theere anything new we can say by looking at the interface as a whole,
# rather than one side at a time
for $chainctr1 ( 0 .. $#chains) {
    $chain = $chains[$chainctr1];
    next if ($too_short{$chain});
    $dir   = $chain;
    for $chain2  (  @{ $identical_chains{$chain}} )  {
	$dir2 = $chain."_identical_chains";
        matching_if_clusters ($chain, $dir, $chain2, $dir2);
    } 
    for $chain2  ( @chains[$chainctr1+1 .. $#chains] ) {
	next if ($too_short{$chain2});

	$dir2 = $chain2;
        matching_if_clusters ($chain, $dir, $chain2, $dir2);
	
	for $chain3 ( @ { $identical_chains{$chain2}} ) {
	    
	    $dir2 = $chain2."_identical_chains";
	    matching_if_clusters ($chain, $dir, $chain3, $dir2);
	}    
    }
}


#######################################################################################
#
#    CREATING AND PROCESSING THE LATEX FILE
#
#######################################################################################

print "creating the latex script ...\n";
# @texfiles should already contain most of the chapter names ...
( -e "$home/texfiles/special.tex")  &&  (push @texfiles, "special.tex");

# make appendix
# list of files
$appendix_string = "\n\\subsection\{Attachments}\n";
$appendix_string .= "The follwing files should accompamy this report:\n";
$appendix_string .= "\\begin\{itemize\}\n";
foreach $attachment (@attachments) {
    $description = $attachment_description {$attachment};
    $attachment =~ s/\_/\\_/g;
    $appendix_string .= "\\item $attachment - $description\n";
}
$appendix_string .= "\\end\{itemize\}\n";
# list of name shorthands used ---> I dunno how to automate names
push @texfiles, "appendix.tex";


$file = "attachments.tex"; #this is actually only the last part of the appendix
open ( OF, ">$home/texfiles/$file" ) || die "Cno $file: $!.\n"; 
print OF  $appendix_string;
close OF;
push @texfiles, $file;

push @texfiles, "tailer.tex";
$texlist = join " ", @texfiles; 
print "$texlist\n";
chdir "$home/texfiles";

# use sed to change the title in header (?)
`sed 's/PROTEINNAME/$pdbname/g' header.tex > tmp`;
`mv tmp header.tex`;
$command = "cat $texlist > report.tex";
(system $command ) && die "Failure concatenating texfiles.\n"; 
$ret = `echo q | latex report.tex `; # to make the thing die if it gets stuck
( $ret =~ /Output written on/ ) || die "$ret\n";
( $ret =~ /Rerun to get cross\-references right/ ) &&  ($ret = `echo q | latex report.tex `);
( $ret =~ /Output written on/ ) || die "$ret\n";

print "dvi produced.\n";

# `xdvi report`; exit;

#######################################################################################
#
#    MAKE OUTPACKAGE
#
#######################################################################################

print "preparing the outpackage ...\n";

`dvips -Ppdf -G0 report.dvi -o report.ps`; 
`ps2pdf  report.ps report.pdf`;
# tar all intersting files (zip  if the win option is given)
$out = $pdbname.".outpackage";
if ( -e "$home/$out" ) {
    `rm -rf  $home/$out`;
}
`mkdir $home/$out`;

$command = "cp report.pdf  $home/$out";
(system $command) && die "File copying failure while preparing $out.\n";


chdir "$home/$pdbname";

foreach $chain (@chains ) {
    next if ( $too_short{$chain});
    chdir $chain;
    $command = "cp";
    foreach $attachment ( @attachments ) {
	( $attachment =~ /$chain/ ) && ( $command .= " ".$attachment);
    }
    $command .= "  $home/$out";
    (system $command) &&  die "File copying failure while preparing $out.\n";
    chdir "..";
   
}
chdir "$home";
if ( $win ) {
    print "the package will include unix2dos converted files\n";
    chdir "$home/$out";
    foreach $file ( @attachments ) {
	next if ( $file =~ /\Z\.ps/);
	next if ( $file =~ /\Z\.eps/);
	next if ( $file =~ /\Z\.pdf/);
	$command = "unix2dos $file";
	(system $command) && die "unix2dos conversion failure.\n";
    }
    chdir "$home";
}   
$date = `date`;
chop $date;
@aux = split " ", $date;
$date = $aux[1].$aux[2].".".substr(pop @aux, 2,2 );
$zipname = $pdbname.".$date".".zip";
( -e  $zipname )  && `rm $zipname`;
$command = "zip -r  $zipname $out";
(system $command) &&  die "Failure zipping the  $out.\n";
`rm -rf $out`;
print "                        ... done\n";

`xpdf texfiles/report.pdf &`;

#######################################################################################
#######################################################################################
#######################################################################################
#######################################################################################
#######################################################################################
#######################################################################################

#######################################################################################
#
#    AUXILLIARY FUNCTIONS
#
#######################################################################################


#######################################################################################
# species breakdown ( using swissprot descr)
sub species() {

    foreach $taxon  ( "eukaryota", "bacteria", "prokaryota", "archaea", "vertebrata", "arthropoda", "fungi", "plantae", "viruses" ) {
	$count{$taxon} = `grep -i $taxon  $chain.pruned.descr | wc -l`;  
	chomp  $count{$taxon};
	print "$taxon 	$count{$taxon}\n";
    }
    $count{"prokaryota"} += $count{"bacteria"};

    %adjective = ( "eukaryota", "eukaryotic", "prokaryota", "prokaryotic", "archaea", "archaean", "bacteria", "bacterial", 
		   "vertebrata", "vertebrate", "arthropoda", "arthropodal", "fungi",  "fungal", "plantae",  "plant", "viruses", "viral" );
    $pdb_msf_descr_string .= "The alignment consists of ";

    @kingdoms = ();
    foreach $taxon  ( "eukaryota", "prokaryota", "archaea", "viruses" ) {
	next if ( !$count{$taxon});
	push @kingdoms, $taxon;
    }

    $last_taxon = $kingdoms[$#kingdoms];
    $first = 1;
    foreach $taxon  ( @kingdoms ) { # turn this into make_list function
	next if (  $count{$taxon} == 0 );
	if ( $first) {
	    $first = 0;
	} else {
	    $pdb_msf_descr_string .= ", ";
	    ($taxon  eq $last_taxon) &&  ($pdb_msf_descr_string .= "and");
	}
	$perc = percent ($count{$taxon}, $no_seqs);
	$pdb_msf_descr_string .= " $perc"."\\% ".$adjective{$taxon};
	if ( $taxon eq "eukaryota" ) {
	    $sum = 0;
	    foreach $phylum  ( "vertebrata", "arthropoda", "fungi", "plantae" ) {
		$sum += $count{$phylum};
	    }
	    if ( $sum ) {
		$sub_first = 1;
		$pdb_msf_descr_string .= " (";
		foreach $phylum  ( "vertebrata", "arthropoda", "fungi", "plantae" ) {
		    next if (  $count{$phylum} == 0 );
		    ( $sub_first ) || ( $pdb_msf_descr_string .= ",");
		    ( $sub_first ) &&  ($sub_first = 0);
		    $perc = percent ($count{$phylum}, $no_seqs);
		    $pdb_msf_descr_string .= " $perc"."\\% $phylum";
		}
		$pdb_msf_descr_string .= ")";
	    }
	}
    }   
    $pdb_msf_descr_string .= " sequences.\n";
    $sum = 0;
    foreach $taxon  ( "eukaryota", "prokaryota", "archaea" ) {
	$sum += $count{$taxon};
    }
    ( $sum == $no_seqs )  ||  ($pdb_msf_descr_string .= " (Descriptions for some sequences were not readily available.)\n");
    print  $pdb_msf_descr_string;

}

#######################################################################
sub percent (@) {
    my $frac = $_[0];
    my $total =  $_[1];
    if ( ! $total ) {
	return " 0";
    } elsif ( $frac==$total) {
	return " 100";
    } else {
 	return sprintf "%5.1d", 100*$frac/$total;
   }
}

#######################################################################
sub process_uniprot () {
    open ( OF, ">$fastafile" ) || die "Cno $fastafile: $!.\n"; 
    @ids = split '\n', `cat $chain.names`;
    foreach $id ( @ids ) {
	$ret = $database{$id};
	if ( defined $ret ) {
	    print OF "> $id\n";
	    @lines = split '\n', $ret;
	    $reading = 0;
	  TOP: foreach $line ( @lines) { 
	      if ( $reading ) {
		  last if ( $line =~ /^SQ/ ||  $line =~ /^XX/ ); 
		  $line =~ s/\"//g;    $line =~ s/\=//g;  $line =~ s/\/translation//g;
		  $line = substr ($line, 21);
		  print OF  "$line\n"; 
	      }elsif ( $line =~ /\/translation/ ) { 
		  $reading = 1; 
		  redo TOP; 
	      } 
	  } 
	}
    }
    close OF;
}

#######################################################################
sub process_nr () {
    $commandline = $path{"fastacmd"}." -d ".$path{"database"}." -p T -t T  -i $chain.names > tmp";
    ( system $commandline) &&  die "fastacmd failure.\n";

    $commandline = $path{"fasta_names_shorten"}." < tmp > $fastafile";
    ( system $commandline) &&  die "fasta_names_shorten failure.\n";
}

#######################################################################
sub four_side_postscript (@) {
    my $script_name = $_[0];
    my $out_name = $_[1];
    %rotation = ( "front", "", "back", "rotate y 180\n", 
		  "top", "rotate x 90\n", "bottom" ,  "rotate x -90\n");

    foreach $side ( "front", "back", "top", "bottom" ) {
	$instructions  = $rotation{$side};
	$instructions .= "translate x 0\n";
	$instructions .= "translate y 0\n";
	$instructions .= "write ps \"$out_name.$side.ps\"\n";
	$instructions .= "quit\n";
	open (OF, ">tmp" ) || die "Cno tmp: $!.\n";
	print OF $instructions;
	close OF;
	$commandline = $path{"rasmol"}." -script $script_name < tmp > /dev/null ";
	( system $commandline) &&  die "rasmol failure.\n";
	`mv  $out_name.$side.ps $home/texfiles`;
    }
    ( -e "tmp" ) && (`rm tmp`); 
    
}
#######################################################################
sub table_header (@) {
    my  $format = $_[0];
    $retstring  = "\\newline \n  \n \{\\tiny \n   \\begin\{tabular\}[h] \{$format\} \n";
    for $ctr ( 1.. $#_ ) {
	($ctr >1 ) && ($retstring .= "  & ");
	$retstring .= "   \{\\bf $_[$ctr] \}  ";
    }
    $retstring .= "      \\\\  \n \\hline\\\\\n";
    return $retstring;
} 
#######################################################################
sub table_tail () {
    return "   \\end\{tabular\}\n \} \n";
}
#######################################################################
sub modification_time (@) {
    my $filename = $_[0];
    my @aux = ();
    if ( -e $filename ) {
	if ( -l $filename ) { # if it's a symlink need different function
                              # otherwise I get the ststs for th file its pointing to
	    @aux = lstat $filename;
	} else {
	    @aux = stat $filename;
	}
	return $aux[9];
    } else {
	return 0;
    }
}
##########################################################################################################
sub if_subsection (@) {
    my $chain2 = $_[0];
    my $name_ext = $chain2;
    my $dummy;

    $file = "$chain.$chain2.geom_epitope";
    return  if ( ! -e  $file );
    ($no_lines, $dummy) =  split " " , `wc -l $file`;
    return  if ($no_lines <= 1 );

    ( " @dnas " =~ $chain2 ) && ( $name_ext .= " (DNA)" );
    ( " @rnas " =~ $chain2 ) && ( $name_ext .= " (RNA)" );
    ( defined $hetname{$chain2} ) && ( $name_ext = $hetname{$chain2} );

    $results_string{$chain}  .= "\n\\subsection\{Residues at the interface with $name_ext\}\n";
    $results_string{$chain}  .= "The following table lists the top $top_percentage\\% residues";
    $results_string{$chain}  .= " at the interface with $name_ext";
    ( defined $hetname{$chain2} ) &&  ( $results_string{$chain}  .= " (". lc $chem_name{$hetname{$chain2}}.")" );
    $results_string{$chain}  .= ".\n";  

    @epitope  = ();
    @distance = ();
    @noc      = ();
    @noc_bb   = ();
    ($id, $aa, $nc, $bb, $min_dist)  = ();
    open (IF, "<$file" ) || die "Cno $file.\n";
    while ( <IF> ) {
	next if (/^\#/ );
	($id, $aa, $nc, $bb, $min_dist) = split;
	push @epitope, $id;
	$distance{$id} = $min_dist;
	$noc{$id} = $nc;
	$noc_bb{$id} = $bb;
	$epi{$id} = 1;
    }
    close IF;
    mutation_table_if (@epitope); 
	    
    make_rasmol_if ($chain2, @epitope);

    $ref = $chain."_$chain2"."_if";
    $results_string{$chain}  .= "Figure \\ref\{$ref\} shows residues in $chain colored by their importance, at the interface with $name_ext.\n";


    $results_string{$chain}  .= "\\begin\{figure\} [t] \{\n";
    $results_string{$chain}  .= " \\epsfig\{file=$psfile,   width=0.5\\linewidth\}\n";

    $both_prot_chains = 0;
    if ( " @dnas " =~ $chain2 ) {
	$results_string{$chain}  .= " \}\n \\caption\{\\label\{$ref\} Residues in $chain, at the interface with DNA ($chain2),  colored
                     by their relative importance.";
	$results_string{$chain}  .= "DNA is colored green.\n";
    } elsif ( " @rnas " =~ $chain2 ) {
	$results_string{$chain}  .= " \}\n \\caption\{\\label\{$ref\} Residues in $chain, at the interface with RNA ($chain2),  colored
                     by their relative importance.";
	$results_string{$chain}  .= "RNA is colored green.\n";
    } elsif ( defined $hetname{$chain2} ) {
	$results_string{$chain}  .= " \}\n \\caption\{\\label\{$ref\} Residues in $chain, at the interface with $hetname{$chain2},  colored
                     by their relative importance.";
	$results_string{$chain}  .= "The ligand ($hetname{$chain2}) is colored green.\n";
    } else {
	$both_prot_chains = 1;
	$results_string{$chain}  .= " \}\n \\caption\{\\label\{$ref\} Residues in $chain, at the interface with $chain2,  colored
                     by their relative importance.$chain2 is shown in backbone representation";
    }
    $results_string{$chain}  .= "(See Appendix for the coloring scheme on the protein chain $chain.)} \n\\end\{figure\}\n";

} 

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




#################################################################################
sub clust_size (@ ) {
    my $cluster = $_[0];
    my $ctr;

    $ctr = 0;
    foreach $residue (split "_", $cluster ) {
	next if ( !$residue );
	$ctr ++;
    }
    return $ctr;
}

#################################################################################
sub rasmol_cluster (@) {
    my $cluster = $_[0];
    my $color = $_[1];
    my $ctr;
    $ctr = 0;
    $rasmol .= "select none \n";
    foreach $residue ( split "_", $cluster) {
	next if ( ! $residue);
	($ctr % 20 )  ||  ($rasmol .= "\nselect SELECTED");
	$rasmol .= ", $residue";
	$ctr++;
    }
    $rasmol .= "\n";
    $rasmol .= "color $color\n";
    $rasmol .= "spacefill\n";
}
#################################################################################

sub mutation_table_if (@) {
    # uses $chain variable from the main program
    chdir "$home/$pdbname/$chain";

    # sort epitope by cvg 
    @epitope_sorted = sort { $cvg{$a} <=> $cvg{$b} } @_;

    # figure out if exists annotation for any of the residues involved
    $exists_annotation = 0;
    foreach $residue (@epitope_sorted) {
	next if ( $gaps{$residue} > $max_gaps);
	next if ( $cvg{$residue}  > $max_cvg);
	if ( defined $annotation{$chain}{$residue} ) {
	    $exists_annotation = 1;
	}
    }

    # table production
    $resctr = 0;
    foreach $residue (@epitope_sorted) {
	next if ( $gaps{$residue} > $max_gaps);
	next if ( $cvg{$residue}  > $max_cvg);
	if ( ! ($resctr % 50)  ) {
	    ( $resctr ) &&  ( $results_string{$chain}  .=  table_tail());
	    if ( $exists_annotation ) {
		$results_string{$chain}  .= table_header ( "r|l|l|l|l|l|l|l", "res no", "aa type",  "substitutions(\\%)", 
							     "cvg ",  "noc (bb)", "min dist",  "mutn suggestns", " annotation");
	    } else {
		$results_string{$chain}  .= table_header ( "r|l|l|l|l|l|l", "res no", "aa type",  "substitutions(\\%)", 
							     "cvg ",  "noc (bb)", "min dist",  "mutn suggestns");
	    }
	}
	@aux = split '',  $subst{$residue}; 
	$substitutions = "";
	foreach $aa ( @aux ) {
	    $substitutions .= $aa;
	    # if substitution appears in < 1% of cases, it is  not listed
	    (  defined $aa_freqs{$chain}{$residue}{$aa} ) &&  ($substitutions .= "(".$aa_freqs{$chain}{$residue}{$aa}.")");
	}
	$commandline = $path{"suggest"}."  $type{$residue}  $subst{$residue}";
	$suggestion = "" || `$commandline`;
	chomp $suggestion;
	$results_string{$chain}  .=  "$residue &  $type{$residue}  &  $substitutions    ";
	$results_string{$chain}  .=  "  &   $cvg{$residue}  &  $noc{$residue} ($noc_bb{$residue})  ";
	$results_string{$chain}  .=  "  &  $distance{$residue}  & $suggestion ";
	if ( $exists_annotation ) {
	    if ( defined  $annotation{$chain}{$residue} ) {
		$results_string{$chain}  .=  " & $annotation{$chain}{$residue}  ";
	    } else {
		$results_string{$chain}  .=  " &   ";
	    }
	}
	$results_string{$chain}  .=  "\\\\\n";
	$resctr++;
    }
    if ($resctr ) {$results_string{$chain}  .=  table_tail()};
    $results_string{$chain}  .= "\n\\vspace\{0.3 in\}\n";

}
#################################################################################

sub mutation_table_surf (@) {
    # sort epitope by cvg
    @epitope_sorted = sort { $cvg{$a} <=> $cvg{$b} } @_;

    # figure out if exists annotation for any of the residues involved
    $exists_annotation = 0;
    foreach $residue (@epitope_sorted) {
	next if ( $gaps{$residue} > $max_gaps);
	next if ( $cvg{$residue}  > $max_cvg);
	if ( defined $annotation{$chain}{$residue} ) {
	    $exists_annotation = 1;
	}
    }
    $resctr = 0;
    foreach $residue (@epitope_sorted) {
	next if ( $gaps{$residue} > $max_gaps);
	next if ( $cvg{$residue}  > $max_cvg);
	if ( ! ($resctr % 50)  ) {
	    ( $resctr ) &&  ( $results_string{$chain}  .=  table_tail());
	    if ( $exists_annotation ) {
		$results_string{$chain}  .= table_header (  "r|l|l|l|l|l", "res no", "aa type",  "substitutions(\\%)", 
							   "cvg ",  "mutation suggestions",  " annotation");
	    } else {
		( $results_string{$chain}  .= table_header ( "r|l|l|l|l", "res no", "aa type",  "substitutions(\\%)", 
							   "cvg ",  "mutation suggestions"));
	    }
	}
	@aux = split '',  $subst{$residue}; 
	$substitutions = "";
	foreach $aa ( @aux ) {
	    $substitutions .= $aa;
	    # if substitution appears in < 1% of cases, it is  not listed
	    (  defined $aa_freqs{$chain}{$residue}{$aa} ) &&  ($substitutions .= "(".$aa_freqs{$chain}{$residue}{$aa}.")");
	}
	$commandline = $path{"suggest"}."  $type{$residue}  $subst{$residue}";
	$suggestion = "" || `$commandline`;
	chomp $suggestion;
	$results_string{$chain}  .=  "$residue &  $type{$residue}  &  $substitutions    ";
	$results_string{$chain}  .=  "  &   $cvg{$residue}   ";
	$results_string{$chain}  .=  "  &   $suggestion ";
	if ( $exists_annotation ) {
	    if ( defined  $annotation{$chain}{$residue} ) {
		$results_string{$chain}  .=  " & $annotation{$chain}{$residue}  ";
	    } else {
		$results_string{$chain}  .=  " &   ";
	    }
	}
	$results_string{$chain}  .=  "\\\\\n";
	$resctr++;
    }
    if ($resctr ) {$results_string{$chain}  .=  table_tail()};
    $results_string{$chain}  .= "\n\\vspace\{0.3 in\}\n";
}


#################################################################################
sub this_and_that ( @) {
    my $last_index = $#_ ;
    if ( $last_index == -1) {return ""};
    if ( $last_index ==  0) {return $_[0]};
    if ( $last_index ==  1) {return "$_[0] and $_[1]"};
    
    $retstring = "$_[0]";
    for $ctr ( 1 .. $last_index-1) {
	$retstring  .= ", $_[$ctr]";
    }
    $retstring  .= ", and $_[$last_index]";
	
}
#################################################################################
sub find_plural ( @) {
    my $last_index = $#_ ;
    if ( $last_index == 0 ) { return ( "", "is")};
     return ( "s", "are");
}



#################################################################################
sub set_colors(){
    @rgb = ( "[0,0,255]", "[255,0,0]", "[255,255,0]", "[0,255,0]", "[160,32,240]", "[0,255,255]",
	      "[64,224,208]",  "[165,42,42]", "[255,127,80]", "[255,0,255]", "[255,160,122]", "[135,206,235]",
	      "[238,130,238]", "[255,215,0]", "[255,228,196]", "[132,112,255]", "[18,112,214]", "[188,143,143]",
	      "[102,205,170]", "[85,107,47]", "[100,149,237]", "[140,140,140]", "[222,184,135]","[50,205,50]", 
	      "[210,180,140]", "[255,140,0]", "[255,20,147]", "[176,48,96]", "[255,235,205]",  "[0,0,0]");

    @color_word = ( "blue","red", "yellow", "green", "purple", "azure", "turquoise", "brown", "coral",
	       "magenta", "LightSalmon", "SkyBlue", "violet", "gold", "bisque", "LightSlateBlue", "orchid", 
	       "RosyBrown", "MediumAquamarine", "DarkOliveGreen", "CornflowerBlue", "grey55", "burlywood", 
	       "LimeGreen", "tan", "DarkOrange", "DeepPink", "maroon", "BlanchedAlmond", "black");

    # assign color to each letter:
    for $ctr ( 0 .. 25 ) {
	$letter = chr(65+$ctr);
	$color{$letter}       = $rgb[$ctr];
	$color_descr{$letter} = $color_word[$ctr];
	# also for numbers
	$color{"$ctr"}        = $rgb[$ctr];
	$color_descr{"$ctr"}  = $color_word[$ctr];
   }
    # empty string
    $color{""} =  "[0,0,255]";
    $color_descr{""} =  "blue";
}

#######################################################################################################
sub surf_clusters (@) {
    my @surf_clust;
    my $chain = $_[0];
    my $dir   = $_[1];

    foreach $residue (keys %cvg) {
	if  (! defined $accessible{$chain}{$residue} ) {
	    print " in surf_clusters: $chain $residue not defined\n";
	}
    }
    
    %shell = (); # this is geometric shell of surface residues, not unix shell
    foreach $residue (keys %cvg) {
	$shell{$residue} = 0;
	#print "$chain   $residue  $gaps{$residue}  $cvg{$residue}  $accessible{$chain}{$residue}\n";
	next if ( $gaps{$residue} > $max_gaps);
	next if ( $cvg{$residue}  > $max_cvg);
	next if ( ! $accessible{$chain}{$residue} );
	$shell{$residue} = 1;
    }
   
    # make the pdb 
    $file = "$dir/$chain.shell.pdb";
    open (OF, ">$file" ) || die "Cno $file.\n";
    $file = "$dir/$chain.pdb";
    open (IF, "<$file" ) || die "Cno $file.\n";
    while (<IF>) {
	$residue  = substr $_, 22, 4;  $residue=~ s/\s//g;
	( $shell{$residue} ) && print OF;
    }
    close IF;
    close OF;

    # find clusters on the surface
    $command = $path{"pdb_cluster"}."   $dir/$chain.shell.pdb  4.0 ";
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

#################################################################################
sub matching_if_clusters (@) {
    my $chain = $_[0];
    my $dir   = $_[1];
    my $chain2 = $_[2];
    my $dir2 = $_[3];
    print " *** $chain  ****  $chain2 ***  $dir  ****  $dir2 *** \n";
    chdir "$home/$pdbname";
    #find contacts btw the two shells
    $commandline = $path{"if_cont"}."  $dir/$chain.shell.pdb $dir2/$chain2.shell.pdb > tmp.epitope";
    ( system $commandline) &&  die "if_count failure.\n";
    my %noc      = ();
    my %noc_bb   = ();
    my %distance = ();
    my %type     = ();
    my $results_string = "";
    my $first = 1;
    ($id1, $aa1, $id2, $aa2, $nc, $bb, $min_dist)  = ();
    $file = "tmp.epitope";
    open (IF, "<$file" ) || die "Cno $file.\n";
    while ( <IF> ) {
	next if (/^\#/ );
	($id1, $aa1, $id2, $aa2, $nc, $bb, $min_dist) = split;
	$noc{$id1}{$id2}      = $nc;
	$noc_bb{$id1}{$id2}   = $bb;
	$distance{$id1}{$id2} = $min_dist;
	$type{$chain}{$id1}   = $aa1;
	$type{$chain2}{$id2}  = $aa1;
    }
    close IF;
    
    
    foreach $cluster1 ( @{ $surf_clust{$chain}} ) {
	foreach $cluster2 ( @{ $surf_clust{$chain2}} ) {
	    $contacts{$cluster1}{$cluster2} = 0;
	}
    }
    foreach $cluster1 ( @{ $surf_clust{$chain}} ) {
	foreach $residue1 ( split "_", $cluster1 ) {
	    next if ( !$residue1);

	    foreach $cluster2 ( @{ $surf_clust{$chain2}} ) {
		foreach $residue2 ( split "_", $cluster2 ) {
		    next if ( !$residue2);
		    if ( defined $noc{$residue1}{$residue2}) {
			$contacts{$cluster1}{$cluster2} ++;
		    }
		}
	    }
	}
    }
    $ctr = 0;
    foreach $cluster1 ( @{ $surf_clust{$chain}} ) {
	$letter1 = substr $chain_names{$chain}, 0, 1;
	foreach $cluster2 ( @{ $surf_clust{$chain2}} ) {
	    $letter2 = substr $chain_names{$chain2}, 0, 1;
	    if ($contacts{$cluster1}{$cluster2} ) {
		$ctr ++;
		# make postscript 
		$psname = "$chain.$chain2.ifclust$ctr.ps";
		if ( modification_time ("$home/texfiles/$psname") <  modification_time ("$home/$pdbname/$chain/$chain.ranks_sorted" ) ) {
		    $commandline = "cat  $chain/$chain.pdb $dir2/$chain2.pdb > tmp.pdb";
		    ( system $commandline) &&  die "cat failure in matching_if_clusters.\n";
		    $rasmol = "load tmp.pdb\n background white\n wireframe off \n  backbone 100\n";

		    rasmol_cluster ($cluster1, $color{$letter1});
		    rasmol_cluster ($cluster2, $color{$letter2});

		    $rasmol .= "write ps \"$psname\"\n quit\n";
		    $file  = "tmp.rs"; 
		    open  (OF, ">$file") || die "Cno $file.\n";
		    print OF $rasmol; 
		    close OF; 
		    $command = $path{"rasmol"}." < tmp.rs > /dev/null";
		    (system $command ) && die "Rasmol failure.\n";  
    
		    $command = "mv  $psname $home/texfiles";  
		    (system $command ) && die "Failure moving  $psname to texfiles.\n"; 
		}
		
		# tex
		if (  $first ) {
		    $first = 0;
		    $results_string = "";
		    $results_string  .= "\n\\section\{$chain - $chain2 interface\}\n";
		    $results_string  .= "\n Two clusters of top  $top_percentage\\% residues come in contact across the $chain/$chain2 interface,";
		    $results_string  .= " as shown in Fig \\ref\{$chain"."$chain2"."ifclust$ctr\}.\n";
		} else {
		    $results_string  .= "\n Another two clusters of top  $top_percentage\\% residues  in contact,";
		    $results_string  .= " are shown in Fig \\ref\{$chain"."$chain2"."ifclust$ctr\}.\n";
		}

		$results_string  .= "\\begin\{figure\} [t] \{\n";
		$results_string .= " \\epsfig\{file=$psname,   width=0.4\\linewidth\}\n";
		$results_string .= " \}\n \\caption\{\\label\{$chain"."$chain2"."ifclust$ctr\} ";
		$results_string .= " Clustering of  residues at the interface between $chain and $chain2.";
	        ( $ctr > 1 ) &&  ($results_string .= "(Case $ctr.)");
		$results_string .= " \}\n \\end\{figure\}\n";

		#table
		$results_string  .= " The residues forming contacts are the following:\n";
		$results_string  .= table_header ( "r|l|r|l|r|r", "res in $letter1", "aa type",   "res in $letter2", "aa type",  
							       "noc (bb)", "min dist");
		    
		foreach $residue1 ( split "_", $cluster1 ) {
		    next if ( !$residue1);
		    foreach $residue2 ( split "_", $cluster2 ) {
			next if ( !$residue2);
			if ( defined $noc{$residue1}{$residue2}) {
			    $results_string  .=  "$residue1 &  $type{$chain}{$residue1}  &  ";
			    $results_string  .=  "$residue2 &  $type{$chain2}{$residue2}  &  ";
			    $results_string  .=  "$noc{$residue1}{$residue2} ($noc_bb{$residue1}{$residue2}) & ";
			    $results_string  .=  " $distance{$residue1}{$residue2} \\\\\n";
			}
		    }
		}

		$results_string  .=  table_tail();
		$results_string  .= "\\vspace {0.3in}\n";
	    }
	}
    }

    if (! $first) {
	$section_name = "if".$chain_names{$chain}.$chain_names{$chain2};
	$file = "$section_name.tex";
	open ( OF, ">$home/texfiles/$file" ) || die "Cno $file: $!.\n"; 
	print OF  $results_string;
	close OF;
	push @texfiles, $file; 
    }
    ( -e "tmp.epitope" ) &&  ( `rm tmp.epitope`);
    ( -e "tmp.pdb" )     &&  ( `rm tmp.pdb`);
    ( -e "tmp.rs" )      &&  ( `rm tmp.rs`);
}





#################################################################################
sub  help_file(){

format STDOUT =

     report_maker should start from the PDB file, and in the end produce an ET  report in the PDF format,
 together with accompanying package of files to be shipped to the user. You can restrart your 
 report making proces from almost any point: seqeunce selection, multiple sequence alignment, or
 running etc.
    report_maker.pl should immediately be followed by the pdb name.
    report_maker takes three optional arguments:
           -win   to produce a windows version of the package (using unix2dos)
           -cvg  <cvg>   where <cvg> is the top percentage of residues to be considered 
                 in the ET analysis
           -cdist <dist> cutoff distance to be used in interface determination
       
    If you have an inroductory story  about your protein, you can put it in a file called 
 texfiles/descr.tex in your working directory - it will be incoprporated in the report.
    Also, if you have an extra chapter(s) and know how to use latex, put the latex file
 in the texfile directory under the name special.tex.
    The script at this point has no general way of deciding which ligands are physiological
 and which are not. You can prepare a list of nonphyisiological residues, and store it as a file
 (one pdb-style "heteroname" per line) in your working directory. The file should be called nonphys.
   
.

    write;


}
