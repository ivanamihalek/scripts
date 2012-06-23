#! /usr/bin/perl -w -I/home/i/imihalek/projects/report_maker/modular/

use strict;



our $HOME;
our @attachments;
our %attachment_description;
our %options;
our %path;
our @pics;
our @texfiles;


our $MAX_ID;
our $PID_LOWEST_ACCEPTABLE;

####################################################################################
####################################################################################
####################################################################################
####################################################################################
####################################################################################
#    BOOTING PROCESS:
####################################################################################
####################################################################################

sub boot () {

    ################################################################################
    #
    #    CHECK FOR DEPENDENCIES
    #
    ################################################################################

    # databases
    $path{"uniprot"}         =   "/home/pine/databases/uniprot_dbm/uniprot_dbm.dat";
    $path{"uniprot_for_blast"}         =   "/home/pine/databases/uniprot";
    $path{"var2uni"}         =   "/home/pine/databases/var2uniprot";
    $path{"pdb_repository"}  =   "/home/pine/pdbfiles";
    $path{"hssp_repository"} =   "/home/pine/hsspfiles";
    $path{"pdbseq"}          =   "/home/pine/databases/pdbseq/pdbaa";  
    $path{"scratchdir"}      =   "/tmp";  

    # programs  and scripts
    $path{"afa2msf"}           = "$HOME/perlscr/translation/afa2msf.pl"; 
    $path{"align_by_template"} = "$HOME/perlscr/msf_manip/align_by_template.pl";  
    $path{"alistat"}           = "/home/protean2/current_version/bin/linux/alistat";
    $path{"blast"}             = "$HOME/bin/blast/blastall";
    $path{"ce"}                = "$HOME/downloads/ce_distr/CE"; 
    $path{"clustalw"}          = "/home/protean2/LSETtools/bin/linux/clustalw";
    $path{"cluster2tex"}       = "$HOME/perlscr/translation/cluster2textable.pl";
    $path{"color_by_cluster"}  = "$HOME/perlscr/pdb_manip/cbc.pl";
    $path{"color_by_coverage"} = "$HOME/perlscr/pdb_manip/cbcvg.pl";
    $path{"if_cont"}           = "$HOME/c-utils/if_cont"; 
    $path{"java"}              = "/home/i/ires/local/jdk1.5.0_06/bin/java ";
    $path{"db_ret"}            = "$HOME/perlscr/database/db_retrieve.pl";
    $path{"dssp"}              = "/home/protean2/current_version/bin/linux//dssp"; 
    $path{"etc"}               = "$HOME/code/etc/wetc";
    $path{"extract_clusters"}  = "$HOME/perlscr/pdb_manip/extract_clusters.pl";   
    $path{"extract_descr"}     = "$HOME/perlscr/var_ID_descr.pl"; 
    $path{"hssp_download"}     = "$HOME/perlscr/downloading/hsspdownload.pl"; 
    $path{"hssp2msf"}          = "$HOME/perlscr/translation/hssp2msf.pl"; 
    $path{"extract_nmr_model"} = "$HOME/perlscr/pdb_manip/extract_nmr_model.pl";
    $path{"extract_from_msf"}  = "$HOME/perlscr/extractions/extr_seqs_from_msf.pl";
    $path{"fasta_cleanup"}     = "$HOME/perlscr/fasta_manip/cleanup_fasta.pl"; 
    $path{"fastacmd"}          = "$HOME/bin/blast/fastacmd";
    $path{"find_ligands"}      = "$HOME/perlscr/pdb_manip/find_ligands.pl"; 
    $path{"geom_epitope"}      = "$HOME/c-utils/geom_epitope"; 
    $path{"geom_center"}       = "$HOME/perlscr/pdb_manip/geom_center.pl"; 
    $path{"mc_postprocess"}    = "$HOME/c-utils/postprocess/postp";
    $path{"msf2afa"}           = "$HOME/perlscr/translation/msf2afa.pl"; 
    $path{"muscle"}            = "$HOME/downloads/muscle3.6/muscle";
    $path{"pdb_cluster"}       = "$HOME/c-utils/pdb_clust/pc"; 
    $path{"pdb_point_place"}   = "$HOME/perlscr/pdb_manip/pdb_point_place.pl"; 
    $path{"pdb_rename"}        = "$HOME/perlscr/pdb_manip/pdb_chain_rename.pl"; 
    $path{"pom"}               = "$HOME/downloads/ce_distr/pom"; 
    $path{"pymol"}             = "/home/pine/pymol/pymol.com";
    $path{"remove_id_from_afa"}    = "$HOME/c-utils/remove_id_from_afa"; 
    $path{"remove_id_from_msf"}    = "$HOME/perlscr/msf_manip/remove_id_msf.pl"; 
    $path{"restrict_msf_to_query"} = "$HOME/perlscr/filters/restrict_msf_to_query.pl";
    $path{"remove_fragments"}      = "$HOME/perlscr/filters/remove_short_msf.pl"; 
    $path{"slct_hom_region"}       = "$HOME/perlscr/fasta_manip/select_homology_region.pl"; 
    $path{"seq_painter"}           = "$HOME/java-utils/SeqReport.class";  
    $path{"slab"}                  = "$HOME/perlscr/pdb_manip/slab_plane.pl"; 
    $path{"suggest"}               = "$HOME/perlscr/suggest_mutations.pl";  
    $path{"texfiles"}              = "$HOME/projects/report_maker/modular" ; 


    # check if all paths ok
    my $program;
    foreach $program ( keys %path) {
	( -e $path{$program} ) || die "$path{$program} not found.\n";
    }
    print "paths OK.\n";

    #alias for clustalw
    $path{"clustalw"}          .= " -output= gcg -quicktree";
    #alias for the seq painter
    $path{"seq_painter"}       = $path{"java"}." -classpath .:/$HOME/java-utils/:/$HOME/java-utils/epsgraphics.jar SeqReport";

    ################################################################################
    #
    #    CREATE DIRECTORY WITH TEXFILES
    #
    ################################################################################

    #set LaTex search  path 
    $ENV{'TEXINPUTS'} = ".:".$path{"texfiles"}.":";
    #print "$ENV{'TEXINPUTS'}\n"; exit;

    ( -e "texfiles" ) || `mkdir texfiles`;
 
    @texfiles = ( "header.tex", "notes.tex", "structure_notes.tex", "appendix.tex", "tailer.tex");
    @pics = ("colorbar_horizontal.eps");
    foreach ( @texfiles, @pics ) {
	(  -e "texfiles/$_" )  && `rm texfiles/$_`;
	`ln -s  $path{"texfiles"}/$_ texfiles/$_`; 
	(  -e "texfiles/$_" ) || die "Error locating/copying $_.";
    } 
    print "tex files and pic   OK.\n";

    @texfiles = (); # reorganize
    push @texfiles, "header.tex";
    ( -e "texfiles/descr.tex" )  || (  `touch texfiles/descr.tex`);

    # push @texfiles, "intro.tex";
    # push @texfiles, "notes.tex";
    #             the rest of the sections will be pushed on as they are created

    @attachments = (); # keep track of things which need to be attached
    %attachment_description = (); 
}


################################################################################
################################################################################
################################################################################

sub read_options ( @) {

    my $options_file = $_[0];
    my $fh;
    my @option_kwds = (  "NAME", "SEQ","FASTA", "ALMT", "PDBF", "MODEL", "MODEL_ALMT", 
			 "DESCR", "BLAST_EVAL", "MAX_ID", "PID_LOWEST", "STRUCT");
    my ($kwd, $option, $kwd_found, $cmd);

    
    $fh = inopen ( $options_file );
    $kwd_found = 0;
    while ( <$fh> ) {
	next if ( ! /\S/ );
	chomp;
	($kwd, $option) = split;
	( grep { (uc $kwd) eq $_} @option_kwds ) || 
	    die "Unrecognized keyword \"$kwd\" in $options_file";
	$options{uc $kwd} = $option;
	$kwd_found = 1;
    }
    $kwd_found || die "$options_file is empty.";
    $fh->close;
    printf "options:\n";
    while (($kwd, $option) = each %options ) {
	print "\t$kwd  $option\n";
    }
    print "\n";
    defined $options{"NAME"} || die "NAME not defined in  $options_file.";
    ( defined $options{"STRUCT"}  &&  (length  $options{"NAME"}) != 4 ) && die "Please replace ".$options{"NAME"}." by a 4 letter name.\n"; 
    # possibilites:
    #  1) SEQ is given - proceed to blast (update blast)
    #  2) FASTA is given - check if NAME exists there, and proceed to alignment
    #  3) ALMT  is given - check if NAME exists there
    #  4) NAME is recognizable as id ---> proceed by finding db input, doing blast, etc
    #  5) failure

    # if PDBF can proceed as if only PDBid given

    if ( defined $options{"MODEL"}) { 
	defined $options{"MODEL_ALMT"} ||
	    die "if MODEL, then alignment must be provided between the MODEL sequence and NAME sequence, called MODEL_ALMT.";
	foreach (  $options{"MODEL"}, $options{"MODEL_ALMT"} ) {
	    ( -e $_) || die "File $_  not found.";
	}
	$cmd = "grep ".$options{"NAME"}."  ". $options{"MODEL_ALMT"};
	`$cmd` ||  die $options{"NAME"}." not found in ".$options{"MODEL_ALMT"};
     }

    (defined $options{"MAX_ID"}) && ( $MAX_ID = $options{"MAX_ID"});
    (defined $options{"PID_LOWEST"}) && ( $PID_LOWEST_ACCEPTABLE = $options{"PID_LOWEST"});
}


1;
