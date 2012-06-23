#!/usr/bin/perl -w 

use strict;
use Figures;
use Report_utils;
use File::Copy;

our $FRAGMENT_LENGTH = 0.75;
our $TOO_SHORT  = 20;
our $TOO_FEW_SEQS  = 10;
our $MAX_ID = 0.99;
our $EVALUE     =  1.e-10;

our %aa_freqs;
our $alistat_footnote;
our %annotation;
our (@attachments, %attachment_description);
our (%chains_in_pdb, %ligands);
our (%chem_name, %synonym); # this is for ligands
our %copies;
our %cvg;
our %hetero;
our ($home);
our ($id, $id_type, $main_db_entry);
our %insertion;
our %interface;
our %interface_notes;
our %is_hssp;
our %is_peptide;
our %map_on_qry;
our $max_cvg;
our (%nucleic, %dna);
our %options;
our @pics;
our %path;
our %pdb_entry;
our @regions;
our %rotated_coordinates ;
our %sequence;
our %sequential; # one of the maps - pdb residue number to sequential number
our (%start, %end, %pid);
our $structure;
our $structure_used_at_least_once;
our %subst;
our @texfiles;
our %type;
our @unique_chains;

our $nmr;

my %mentioned = ();

######################################
sub emit (@) { 
   my ($file, $tex_string) = @_;
   my ($fh);
   print "\temitting $file\n";
   $fh = outopen ($file);
   print $fh   $tex_string;
   $fh->close;
   `mv $file $home/texfiles`;

   push @texfiles, $file;
}
######################################
sub not_enough_seqs_blurb ( @) { 
    my $id = $_[0];
    my $texstring = "";
    $texstring = "\\section{Chain $id}\n";
    $texstring .= "For chain $id, not enough different sequences could be found to do ";
    $texstring .= "reasonable and informative analysis. The limits used were: ";
    $texstring .= "at least $TOO_FEW_SEQS sequences, no more than ". percent ( $MAX_ID, 1.0). "\\% identical with $id, ";
    $texstring .= " but having similarity which puts them  within E-value of $EVALUE in the Blast search ";
    $texstring .= " for $id against UniProt database\n"; 
    return $texstring;
}
######################################
sub not_enough_full_length_seqs_blurb ( @) { 
    my $id = $_[0];
    my $texstring = "";
    my @regions_short = ();
    my ($region, $region_start, $region_end, @seqs);


    $texstring = "\\subsection{Homologue availability}\n";
    $texstring .= "For chain $id, not enough (at least  $TOO_FEW_SEQS) homologues, covering the full length of the sequence, ";
    $texstring .= "could be found to do a reasonable and informative analysis. ";
    $texstring .= "It was possible, however, to locate enough homolgues in the region";
    if ( @regions > 1 ) {
	$texstring .= "s";
    }
    $texstring .= "  ";
    foreach $region( @regions )  {
	($region_start, $region_end,  @seqs) = split " ", $region;
	push @regions_short, $region_start."--".$region_end ;
    }
    $texstring .= this_and_that (@regions_short);
    $texstring .= ".\n";
    return $texstring;
}
######################################
sub rationale ( @) { 
    my $name = $_[0];
    my $pdbname;
    my $tex_string = "";
    my $intro = 0;
    my $emphasis = 1;

    ($id =~ $name ) && return "";


    $tex_string .= "\\subsection{Rationale}\n";
    if ( $pid{$name} < 95 ) {
	$tex_string .= "To model $id in the region  between residues $start{$name} and $end{$name} "; 
	if ( defined $options{"MODEL"} ) {
	    $tex_string .= "we use the structure ".  $options{"MODEL"}.", provided by the user of report\\\_maker.\n";
	} else {
	    $tex_string .= "we use $name, which in this region matches $id with ".percent ($pid{$name}, 100)."\\% identity.\n";
	}
    } else {
	$tex_string .= "A structure for  $id in the region  between residues $start{$name} and $end{$name} "; 
	$tex_string .= "is available in PDB entry  $name, which in this region matches $id with  ".percent ($pid{$name}, 100)."\\% identity.\n";
    }

    if ( ! defined $options{"MODEL"} ) {
	$pdbname = substr $name, 0, 4;
	$tex_string .= pdb_intro_text ( $intro, $emphasis, $pdbname, $pdb_entry{$pdbname});
    }
    return $tex_string;

}

sub mutation_table_if (@);
######################################
sub fctl_surf_text (@) {
   print "\tfctl surf text\n";
   my ($name, $min_dist_cvg, $min_dist_rank) = @_;
   my $tex_string = "";
   my $binding_partner;
   my ($psfile, $ref);
   my $na_type = "";
   my $mut_table_tex = "";
   my $current_coverage = int (100*$min_dist_cvg);
   ( defined %{$interface{$name}}) || return $tex_string;
   
   foreach $binding_partner ( keys %{$interface{$name}} ) {

       $ref = $name."_$binding_partner"."_if"; 
       $na_type = "";
       if ( defined  $nucleic{$binding_partner} ) {
	   $na_type = "RNA";
	   (defined $dna{$binding_partner}) && ( $na_type = "DNA");
       }
       print "\t*****$na_type********\n";
       # find residues which actually appear at the interface
       print "\t\t$binding_partner ";
       $mut_table_tex = mutation_table_if ( $name, $binding_partner, $min_dist_cvg, $ref."_tbl", 
					    $interface{$name}{$binding_partner} );
       if ( ! $mut_table_tex ) {# nothing shows up at the interface
				    print " ---> nothing at the if\n";
	   next; 
       } else {
	   print "\n";
       }

       # figure production 
       $psfile = make_pymol_if ($name, $binding_partner, $ref); # in Pymol.pm
       
       # text production
       if ( ! $tex_string)  {
	   $tex_string  .= "\\subsubsection{Overlap with known functional surfaces at $current_coverage\\% coverage.}";
	   $tex_string  .= " The name of the ligand is composed of the source PDB identifier and the heteroatom";
	   $tex_string  .= " name used in that file.\n";
       }
       if ( $na_type ) { 
	   $tex_string .="\n\{\\bf \u$na_type binding site. \}"; 
       } elsif ( $is_peptide {$binding_partner} ) {
	   $tex_string .="\n\{\\bf Interface with the peptide $binding_partner. \}";
       } elsif ( defined $hetero{$binding_partner} ) {
	   $tex_string .="\n\{\\bf \u$chem_name{$hetero{$binding_partner}} binding site. \}";
        } else {
	   $tex_string .="\n\{\\bf Interface with  $binding_partner.\}";
       }
       if ( defined $interface_notes{$name}{$binding_partner} ) {
	   $tex_string .= "\u$interface_notes{$name}{$binding_partner}.";
	   if (  $interface_notes{$name}{$binding_partner} =~ /analogy/ ) {
	       my (@aux, $pdbname);
	       @aux = split  " ", $interface_notes{$name}{$binding_partner};
	       $pdbname = substr $aux[3], 0, 4;
	       if ( ! defined $mentioned{$pdbname} ) {
		   my $intro = 0;
		   my $emphasis = 0;
		   $tex_string .= pdb_intro_text ( $intro, $emphasis, $pdbname, $pdb_entry{$pdbname});
	       }
	   }
	   $tex_string .= "\n";
       }

       $tex_string  .= $mut_table_tex;

       #figure
       $tex_string  .= "\\begin\{figure\} [h] \{\n";
       $tex_string  .= "\\center\n";
       $tex_string  .= "\\includegraphics[width=80mm] \{$psfile\}\n";
       if ( $na_type ) {
	   $tex_string  .= " \}\n \\caption\{\\label\{$ref\} Residues in $name, at the interface with $na_type ($binding_partner), colored
                     by their relative importance. ";
	   $tex_string  .= "$na_type is colored green.\n";
       
       } elsif ( defined $hetero{$binding_partner} ) {
	   $tex_string  .= " \}\n \\caption\{\\label\{$ref\} Residues in $name, ";
	   $tex_string  .= " at the interface with $chem_name{$hetero{$binding_partner}},  colored
                     by their relative importance. ";
	   $tex_string  .= "The ligand ($chem_name{$hetero{$binding_partner}}) is colored green. \n";
       } else {
	   $tex_string  .= " \}\n \\caption\{\\label\{$ref\} Residues in $name, at the interface with $binding_partner, colored
                     by their relative importance. $binding_partner is shown in backbone representation";
       }
       if ( defined $hetero{$binding_partner} ) {
	   $tex_string  .= "Atoms further than 30\$\\AA\$ away from the geometric center of the ligand, ";
           $tex_string  .= "     as well as on the line of sight to the ligand were removed.";
       }
       $tex_string  .= " (See Appendix for the coloring scheme for the protein chain $name.) }\n\\end\{figure\}\n";
      
       #accompanying text
       $tex_string  .= "Figure \\ref\{$ref\} shows residues in $name colored by their importance,"; 
       $tex_string  .= " at the interface with ";
       if ( $na_type ) {
	   $tex_string  .= "$binding_partner ($na_type). \n"; 
       } elsif ($chem_name{$binding_partner}) {
	   $tex_string  .= "$chem_name{$binding_partner}. \n"; 
       } else {
	   $tex_string  .= "$binding_partner. \n"; 
       }
  }


    return $tex_string;
}

######################################
sub clusters_text (@) {

    my ($name, $min_dist_cvg, $min_dist_rank) = @_;
    my $commandline;
    my $side;
    my $tex_string = "";
    my $current_coverage = int (100*$min_dist_cvg);
    my $ref;
    my ($format, $caption, @header_fields);
    my $pdbname;
    my $exists_annotation;
    my $residue;
    

    $pdbname = substr $name, 0, 4;

    print "\tclusters text\n";
    

    # make pymol script for color-by-coverage
    if ( modification_time ("$name.ranks_sorted.pml" ) < modification_time ("$name.ranks_sorted" ) ) {
	$commandline = $path{"color_by_coverage"}."  $name.ranks_sorted  $name.pdb $name.ranks_sorted.pml";
	( system $commandline) &&  die "Error: cbcvg failure.";
    }
    # make postscriptfiles (cbcvg figures)
    if (  modification_time ("$home/texfiles/$name.front.ps" ) < modification_time ("$name.ranks_sorted.pml" ) ) {
  	four_side_postscript ( "$name.ranks_sorted.pml", $name);
    }
    # the text to go with cbcvg
    $tex_string  .= "Figure \\ref\{cbcvg$name\} shows residues in $name colored by their importance:\n";
    $tex_string  .= "bright red and yellow indicate more conserved/important residues ";
    $tex_string  .= " (see Appendix for the coloring scheme).";
    $tex_string  .= " A Pymol script for producing this figure can be found in the attachment.\n";


    $tex_string  .= "\\begin\{figure\} [h] \{\n\\center\n";
    foreach $side ( "front", "back", "top", "bottom" ) {
	$tex_string  .= "\\includegraphics[height=40mm,  width=40mm] {$name.$side.ps}\n";
    }
    $tex_string  .= " \}\n \\caption\{\\label\{cbcvg$name\} Residues in $name, colored
                     by their relative importance. Clockwise: front, back, top and bottom views.} \n\\end\{figure\}\n";


    $tex_string  .= "\\subsubsection{Clustering of residues at $current_coverage\\% coverage.}\n";
    # plot clusters at $min_dist_cvg
    if ( modification_time ("$name.clusters.rank=$min_dist_rank.pml" ) < modification_time ("$name.clusters" ) ) {
	$commandline = $path{"color_by_cluster"}." $name.clusters $name.pdb  $min_dist_rank  ";
	(system $commandline) &&  die "Error: color by cluster  failure.";
   }
	 
    if ( modification_time ("$home/texfiles/$name.cluster$min_dist_rank.front.ps")  <  
	 modification_time ("$name.clusters.rank=$min_dist_rank.pml")	 ) {
	four_side_postscript ( "$name.clusters.rank=$min_dist_rank.pml", "$name.cluster$min_dist_rank");
    }
    $tex_string  .= "Fig. \\ref\{cbcluster$name\} shows the top $current_coverage\\% of all residues, ";
    $tex_string  .= "this time colored according to clusters they belong to.\n";
    $tex_string  .= "\\begin\{figure\} [h] \{\n";
    
    foreach $side ( "front", "back", "top", "bottom" ) {
	$tex_string  .= "\\includegraphics[height=40mm,  width=40mm] {$name.cluster$min_dist_rank.$side.ps}\n";
    }
    $tex_string  .= " \}\n \\caption\{\\label\{cbcluster$name\} Residues in $name, colored";
    $tex_string  .= " according to the cluster they belong to: red, followed by blue and yellow ";
    $tex_string  .= " are the largest clusters (see Appendix for the coloring scheme).";
    $tex_string  .= "  Clockwise: front, back, top and bottom views. The corresponding Pymol script is attached.} \\end\{figure\}\n";

    # find clusters at that coverage - list them in a table
    $tex_string  .= " The clusters in Fig.\\ref\{cbcluster$name\} are composed of the residues ";
    $ref = "cbcluster$name"."_tbl";
    $tex_string  .= "listed in Table \\ref\{$ref\}.\n";
    $format = "l|r|l";
    @header_fields = ( "cluster color", "size",  "member residues");
    $caption = "Clusters of top ranking residues in $name.";
    
    $tex_string  .= table_header ( $format, $ref, $caption, @header_fields);

    $commandline = $path{"cluster2tex"}." $name.clusters  $min_dist_rank  > tmp";
    ( system $commandline ) && die "Error running\n$commandline.";
    $tex_string  .= `cat tmp`;
    $tex_string  .= table_tail();

=pod
    # this is just too boring to read
    # if there is any annotation available put it here
    if ( defined $annotation{$name} ) {
	$exists_annotation = 0;
	foreach $residue ( keys  %{$annotation{$name}} ) {
	    next if ( ! defined $cvg{$name}{$residue} ); # I've see Ca atoms annnotated - one wouldn't believe
	    next if ( 	$cvg{$name}{$residue} > $min_dist_cvg );
	    $exists_annotation = 1;
	    last;
	}
	if ( $exists_annotation ) {
	    $tex_string  .= "\nFor these residues, the following annotation is available from $pdbname:  ";
	    foreach $residue ( keys  %{$annotation{$name}} ) {
		next if ( ! defined $cvg{$name}{$residue} );
		next if ( $cvg{$name}{$residue} > $min_dist_cvg );
		if ( @{$annotation{$name}{$residue}} < 2 ) {
		    $tex_string  .= " ".$type{$name}{$residue}."$residue ";
		    $tex_string  .= " ".this_and_that ( @{$annotation{$name}{$residue}} ).". \n";
		}
	    }
	}
    }
=cut
    return $tex_string;

}
#################################################################################
sub clust_size (@ ) {
    my $cluster = $_[0];
    my ($residue,$ctr);

    $ctr = 0;
    foreach $residue (split "_", $cluster ) {
	next if ( !$residue );
	$ctr ++;
    }
    return $ctr;
}

######################################
sub hypo_surf_text (@) {
   print "\thypo surf text\n";
   my ($name, $min_dist_cvg, $min_dist_rank) = @_;
   my $tex_string = "";
   my %surf_clust;
   my $current_coverage = int (100*$min_dist_cvg);
   my (@unassigned_clusters, $cluster, $known_partner);
   my $new_interface;
   my ($cluster_ctr, $psfile,  $psfile2, $ref, $ref2, %belongsto);
   my (@vol_clusters, %vc_size, $vol_cluster,  $cluster_size, @mother_clusters, $diff);
   my $residue;
   my ($overlap, $string, $ret, $pdbname);

   $pdbname = substr $name, 0, 4;

   # see if there is anything like surface clusters
   @{$surf_clust{$name}}  =  surf_clusters ( $name); # I'll use it at the chain-chain if too
   return "" if ( ! @{$surf_clust{$name}} );
   print "\tsurf clusters found\n";
   # do these clusters belong to known interfaces?
   @unassigned_clusters = ();
   foreach $cluster (@{ $surf_clust{$name} }) {
       $new_interface = 1;
       foreach $known_partner ( keys  %{$interface{$name}} ) {
	   if ( compare_if_w_cluster ( $interface{$name}{$known_partner}, $cluster ) eq "same" ) {
	       $new_interface = 0;
	       last;
	   }
       }
       ($new_interface) && push @unassigned_clusters,  $cluster;
   }
   return "" if ( ! @unassigned_clusters);
   print "\tsome surf clusters unassigned\n";
   
   if (! $tex_string) {
       $tex_string  .= "\\subsubsection{Possible novel functional surfaces at $current_coverage\\% coverage.}\n";
   } else {
       $tex_string  .= "\\subsubsection{Other (possible) functional surfaces at $current_coverage\\% coverage.}\n";
   }
   

   $cluster_ctr = 0;
   foreach $cluster (@unassigned_clusters) {

       $psfile = "$name.surfclust$cluster_ctr.ps";
       $ref    = $name."surfclust$cluster_ctr";
       ##############################################################
       #make pymol
       surfclust_pymol ($name, $cluster, $psfile, $ref);

       ##############################################################
       # relate it back to the overall clusters
       $ret =  `$path{"extract_clusters"} $name.clusters  $min_dist_rank`;
       ($ret) ||  die "Error: Failure extracting clusters.";
       @vol_clusters = split '\n', $ret;

       $cluster_size = clust_size ($cluster);
       @mother_clusters = ();
       foreach $vol_cluster ( @vol_clusters) {
	   $overlap = 0;
	   foreach $residue ( split "_", $cluster) {
	       next if (!$residue);
	       $string = "_$residue"."_";
	       ( $vol_cluster =~ $string ) &&  ($overlap ++);
	   }
	   ( $overlap ) && ( push @mother_clusters,  $vol_cluster);
	   $vc_size{$vol_cluster} = clust_size($vol_cluster);
       }
	    
       %belongsto = ();
       foreach $vol_cluster ( @mother_clusters) {
	   $diff = $vc_size{$vol_cluster} -  $cluster_size;
	   if ( $diff ) {
	       if ( $diff  < 4 ) {
		  # $buried = 1;
	       } else {
		   $belongsto{$vol_cluster} = 1;
	       }
	   } else {
	      # $same = 1;
	   }
       }		

       # if this is a part of larger cluster, make a fig to show it
       if ( %belongsto ) {
	   $psfile2 = "$name.surfclust$cluster_ctr.2.ps";
	   $ref2 = $ref."2";
	   mother_of_surfclust ($name, $cluster, $psfile2, $ref2, @mother_clusters);
       }

       ##############################################################
       #include the figure in the text
       if ( ! $cluster_ctr  ) {
	   $tex_string  .= "One group of residues is conserved on the $name surface, away from (or susbtantially larger than)";
	   $tex_string  .= "  other functional sites and interfaces recognizable in PDB entry $pdbname.";
	   $tex_string  .= " It is shown in Fig. \\ref{$ref}.";
       } else {
	   $tex_string  .= " Another group of surface residues is shown in ";
	   $tex_string  .= "  Fig.\\ref{$ref}.";
       }
       (%belongsto) &&   ($tex_string .= "  The right panel shows (in blue) the rest of the larger cluster this surface belongs to.");
       $tex_string  .= "%\n\\begin\{figure\} [h] \{\n\\center\n";  
       if  (%belongsto) {
	   $tex_string  .= "\\includegraphics[height=40mm, width=40mm] {$psfile}\n";
	   $tex_string  .= "\\includegraphics[height=40mm, width=40mm] {$psfile2}\n";
       } else {
	   $tex_string  .= "\\includegraphics[height=80mm, width=80mm] {$psfile}\n";
       }
       if ( ! $cluster_ctr ) {
	   $tex_string  .= " \}\n \\caption\{\\label\{$ref\} A possible active surface on the chain $name.\n";
	   (%belongsto) &&   ($tex_string .= "The larger cluster it belongs to is shown in blue.\n");
       } else {
	   $tex_string  .= " \}\n \\caption\{\\label\{$ref\} Another  possible active surface on the chain $name. ";
 	   (%belongsto) &&   ($tex_string .= "The larger cluster it belongs to is shown in blue.\n");
      }
       $tex_string  .= "\}\n \\end\{figure\}\n";

       ##############################################################
       # table of residues and disruptive mutations
       $tex_string  .= mutation_table_surf ($name, $ref."_table", $cluster); 


       ##############################################################
       $cluster_ctr ++;
   }

  return $tex_string;
}

sub sequence_description(@);

######################################
sub primary_seq_text(@){

    my ($name) = @_;
    my @figure_pieces = ();
    my ($msf_descr_string, $tex_string);
    my ($label, $label_base, $number_of_fig_pieces);
    my ($file, $numbers, $ctr, @aux);
    my ($orig_name, $title_name);

    printf "\tprimary seq text\n";

    # sequence description
    $msf_descr_string = sequence_description ($name); # below
    # seq paint
    @figure_pieces = make_seq_portrait ($name); # in Figure.pm
    # table

    # name resolving for the case of a fragment
    if ( $name =~/(\w+)\.(\d+)\.(\d+)/ ) { # this name form reserved for fragments
	$orig_name = $1;
	$title_name = "the region $2--$3";
    } else {
	$title_name = $name;
	$orig_name = $name;
    }
    # text
    $tex_string  =  "";
    $tex_string .=  $msf_descr_string;
    $tex_string .=  "\\subsection {Residue ranking in $title_name}\n";
    # the text that goes with  the sequence figure
    $number_of_fig_pieces = $#figure_pieces +1;
    $label_base = "seqpaint$name"; 

    if ( $orig_name eq $name ) {
	$tex_string  .= "The $name sequence is shown in "; 
    } else {
	$tex_string .= "$orig_name, in $title_name  is shown in "; 
    }
    if ( @figure_pieces > 1 ) {
	$tex_string  .= " Figs. \\ref\{$label_base"."1\}--\\ref\{$label_base"."$number_of_fig_pieces\}, ";
    } else { 
	$label = $label_base."1";
	$tex_string  .= " Fig. \\ref\{$label_base"."1\}, ";
    } 
    $tex_string .= " with each residue colored according to its estimated importance.\n";  
    for $ctr ( 1 .. $number_of_fig_pieces) {  
	$label = $label_base.$ctr; 
	$tex_string  .= "\\begin\{figure\}  \{\n\\center\n"; 
	$file = $figure_pieces[$ctr-1];
	$tex_string  .= "\\includegraphics[width=80mm] {$file}\n"; 
	@aux = split '\.', $file; 
	pop @aux; 
	$numbers =  pop @aux;
	$numbers =~ s/_/\-/;
	($numbers =~/^_/ ) && ($numbers =~ s/-//);
	$tex_string  .= " \}\n \\caption\{\\label\{$label\} Residues $numbers in $orig_name colored
                     by their relative importance. (See Appendix, Fig.\\ref{colorbar}, for the coloring scheme.)";
	( $insertion{$name}) &&  ($tex_string .= " Note that some residues in $name carry insertion code.\n");
	$tex_string  .= "} \n\\end\{figure\}\n";
    }


    $tex_string  .= "The full listing of residues in $name can be found in the file called $name.ranks\\_sorted ";
    $tex_string  .= " in  the attachment.\n";
    push @attachments, "$name.ranks_sorted";
    $attachment_description{"$name.ranks_sorted"} = " full listing of residues and their ranking for $name";
  

    printf "\treturninng from primary seq text\n"; 
    return $tex_string 
}

######################################
sub sequence_description(@){

    my $name = $_[0];
    my $msf_descr_string;
    my ($commandline, $ret);
    my ($no_seqs, $conserved);
    my $almt_length;
    my ($orig_name, $title_name);

    printf "\t\t sequence description\n";
    # make new list of names, just in case
    `grep Name  $name.msf | awk \'\{print \$2\}\' > $name.names`;
    ($no_seqs) = split " ",  `wc -l $name.names`; chomp $no_seqs;
    ($ret, $almt_length) = split " ",  `grep \'MSF:\' $name.msf`;

    if ( $name =~/(\w+)\.(\d+)\.(\d+)/ ) { # this name form reserved for fragments
	$orig_name = $1;
	$title_name = "the region $2--$3";
    } else {
	$title_name = $name;
	$orig_name = $name;
    }
    $msf_descr_string = "\\subsection\{Multiple sequence alignment for $title_name\}\n";

    if ( $orig_name eq $name ) {
	$msf_descr_string .= "For the chain $name, the alignment $name.msf (attached) with $no_seqs sequences was used."; 
    } else {
	$msf_descr_string .= "For $orig_name in  $title_name, the alignment $name.msf (attached) with $no_seqs sequences was used."; 
	
    }
    if ( $is_hssp{"$name.msf"} ) {
	$msf_descr_string .= " The alignment was downloaded from the HSSP database, and fragments shorter than 75\\% of the query";
	$msf_descr_string .= " as well as  duplicate sequences were removed. ";
    } else {
	$msf_descr_string .= " The alignment was assembled through combination of BLAST searching on the UniProt database ";
	$msf_descr_string .= " and alignment using Muscle program. ";
    } 
    $msf_descr_string .= " It can be found in the attachment to this report, under the name of $name.msf.";
    push @attachments, "$name.msf";  
    $attachment_description {"$name.msf"} = "the multiple sequence alignment used for the chain $name"; 

    # alistat	
    $commandline = $path{"alistat"}." $name.msf | tail -n 12| head -n 11 ";
    $ret =  `$commandline`;
    ($ret) || die "Error: $name: alistat failure.";
    $ret =~ s/\#/number of/g;

    $msf_descr_string .= " Its statistics, from the \\emph{alistat} program are the following";
    $msf_descr_string .= ":\n\n\\vspace\{0.2in\}";
    $msf_descr_string .= "\\begin{minipage}{0.45\\linewidth} \n"; # minipage for the alistat output
    $msf_descr_string .= "\\centering\n";
    $msf_descr_string .= "\\begin\{verbatim}\n$ret \n \\end\{verbatim\}\n";
    $msf_descr_string .= "\\end{minipage}\n\n";

    # consensus size
    $ret = `awk \'\$1 != \"%\" && \$1>0 && \$4==1 \' $name.ranks | wc -l`;
    chomp $ret;
    $conserved = percent ( $ret,$almt_length ); 
    $msf_descr_string .= "\n Furthermore, $conserved\\% of residues show as  conserved in this alignment.\n\n"; 

    # sequence description
    if ( -e "$name.custom.descr" ) {
	( -e  "$name.descr" ) && `rm $name.descr`;
	`ln -s $name.custom.descr $name.descr`;
    } elsif ( !  -e "$name.descr" || ! -s "$name.descr" ||  modification_time ("$name.descr" ) < modification_time ("$name.names" )  )  {
	$commandline = $path{"extract_descr"}." < $name.names > $name.descr ";
	(system $commandline) && die "Error extracting sequence description.";
    }
   
    #count species
    $msf_descr_string .= species("$name.descr", $no_seqs);
    
    $msf_descr_string .= "The file containing the sequence descriptions can be found in the attachment, under the name $name.descr.\n";
    push @attachments, "$name.descr"; 
    $attachment_description {"$name.descr"} = "description of sequences used in $name msf";

    return $msf_descr_string;
    
}

#######################################################################################
# species breakdown
sub species(@) {
    my  ($descr_file, $no_seqs) = @_;
    my $spec_descr_string = "";
    my ($taxon, %count, %adjective, @kingdoms );
    my ($last_taxon, $phylum, $first, $perc, $sum, $sub_first);
    
    %count = ();%adjective = (); @kingdoms = ();

    foreach $taxon  ( "eukaryota", "bacteria", "prokaryota", "archaea", "vertebrata", "arthropoda", "fungi", "plantae", "viruses" ) {
	$count{$taxon} = `grep -i $taxon  $descr_file | wc -l`;  
	chomp  $count{$taxon};
    }
    $count{"prokaryota"} += $count{"bacteria"};

    %adjective = ( "eukaryota", "eukaryotic", "prokaryota", "prokaryotic", "archaea", "archaean", "bacteria", "bacterial", 
		   "vertebrata", "vertebrate", "arthropoda", "arthropodal", "fungi",  "fungal", "plantae",  "plant", "viruses", "viral" );
    $spec_descr_string .= "The alignment consists of ";

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
	    $spec_descr_string .= ", ";
	    ($taxon  eq $last_taxon) &&  ($spec_descr_string .= "and");
	}
	$perc = percent ($count{$taxon}, $no_seqs);
	$spec_descr_string .= " $perc"."\\% ".$adjective{$taxon};
	if ( $taxon eq "eukaryota" ) {
	    $sum = 0;
	    foreach $phylum  ( "vertebrata", "arthropoda", "fungi", "plantae" ) {
		$sum += $count{$phylum};
	    }
	    if ( $sum ) {
		$sub_first = 1;
		$spec_descr_string .= " (";
		foreach $phylum  ( "vertebrata", "arthropoda", "fungi", "plantae" ) {
		    next if (  $count{$phylum} == 0 );
		    ( $sub_first ) || ( $spec_descr_string .= ",");
		    ( $sub_first ) &&  ($sub_first = 0);
		    $perc = percent ($count{$phylum}, $no_seqs);
		    $spec_descr_string .= " $perc"."\\% $phylum";
		}
		$spec_descr_string .= ")";
	    }
	}
    }   
    $spec_descr_string .= " sequences.\n";
    $sum = 0;
    foreach $taxon  ( "eukaryota", "prokaryota", "archaea", "viruses" ) {
	$sum += $count{$taxon};
    }
    ( $sum == $no_seqs )  ||  ($spec_descr_string .= " (Descriptions of some sequences were not readily available.)\n");

    return $spec_descr_string;

}


######################################
sub text_format() {

    my ($appendix_string, $attachment, $description);
    my ($file, $fh);
    my $texlist;
    my ($command, $ret);
    my $header_text;
    print "creating the latex script ...\n";
    # @texfiles should already contain most of the chapter names ...
    ( -e "$home/texfiles/special.tex")  &&  (push @texfiles, "special.tex");

    chdir "$home/texfiles";
    #check if I have the  intro fig
    $file = "inftro_fig.eps";
    if (  -e $file ) {
	`ln -s  $path{"texfiles"}/$file .`;
	(  -e $file ) || die "Error locating/copying $file";
    } 
    # make appendix$structure_used_at_least_once
    # list of files
    push @texfiles, "notes.tex";
    $structure_used_at_least_once &&  push @texfiles, "structure_notes.tex";
    if ( @attachments) {
	$appendix_string = "\n\\subsection\{Attachments}\n";
	$appendix_string .= "The following files should accompany this report:\n";
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
	$fh = outopen ($file);
	print $fh   $appendix_string;
	$fh->close;

	push @texfiles, $file;
    }
   
    push @texfiles, "tailer.tex";
    $texlist = join " ", @texfiles; 
    print "$texlist\n";

    # use sed to change the title in header (?)
    `sed 's/PROTEINNAME/$id/g' header.tex > tmp`;
    `mv tmp header.tex`;
    $header_text = "";
    if (  -e "$home/texfiles/intro_fig.eps" ) {
	$header_text = "{\n\\center\n\\includegraphics[ width=80mm] {intro_fig.eps}\}\n";
    }
    $header_text .= "\\tableofcontents\n";
    $fh = appopen("header.tex");
    print $fh $header_text;
    $fh->close;

    #print `cat $texlist`;
    ( -e "$id\_report.tex" ) && `rm  $id\_report.tex`;
    $command = "cat $texlist > $id\_report.tex";
    (system $command ) && die "Error: Failure concatenating texfiles.";  
    $ret = `echo q | latex $id\_report.tex `; # to make the thing die if it gets stuck 
    ( $ret =~ /Output written on/ ) || die "Error: $ret";
    #if  ( $ret =~ /Rerun to get cross\-references right/ ) {
    if  ( 1 ) { # always run twice
	$ret = `echo q | latex $id\_report.tex `;
	($ret =~ /Output written on/ ) || die "Error: $ret";
    }

    print "dvi produced.\n";

    #`xdvi $id\_report`; exit;

}


################################################
sub uniprot_intro_text (@) {

    my ($file, $chain, $uniprot_descr, $pct_identity) = @_;
    my $tex_string = "";
    my ($line, @lines);
    my ($writing_os, $writing_oc, $writing_de, $wrote_copyright, $skip);
    my ($fh);
    my  ($comment_name, $uniprot_id);

    $uniprot_descr =~ s/_/\\_/g;
    @lines = split '\n', $uniprot_descr;

    if ($file eq  "intro.tex" ) {
	$uniprot_id = $chain;
	$tex_string = "\\section\{Introduction\}\n";
	$tex_string .= "From SwissProt, id $uniprot_id:\n\n";
    } else {
	($uniprot_id) = split " ", $lines[0];
	$tex_string .= "\\subsection\{$uniprot_id overview\}\n";
	$tex_string .= "From SwissProt, id $uniprot_id, ".percent ($pct_identity,100)."\\% identical to $chain:\n\n";
    }
    $writing_os = $writing_oc = $writing_de = $wrote_copyright = $skip = 0;

    foreach $line ( @lines ) {
	if  ( $line =~ /^OS/ ) {
	    if ( ! $writing_os ) {
		$tex_string .= "\n\\noindent{\\bf Organism, scientific name:}\n";  
		$writing_os = 1.0;
	    }
	    $line =~ s/OS//;
	    $line =~ s/_/ /g;
	    $tex_string .=  "$line\n";
	} elsif  ( $line =~ /^OC/ ) {
	    if ( ! $writing_oc ) {
		$tex_string .= "\n\\noindent{\\bf Taxonomy:}\n";  
		$writing_oc = 1.0;
	    }
	    $line =~ s/OC//;
	    $tex_string .=  "$line\n";
	} elsif  ( $line =~ /^DE/ ) {
	    if ( ! $writing_de ) {
		$tex_string .= "\n\\noindent{\\bf Description:}\n";  
		$writing_de = 1.0; 
	    }
	    $line =~ s/DE//; 
	    $line =~ s/_/ /g;
	    $tex_string .=  "$line\n" ;
	} elsif ( $line =~ /^CC/ ) {
	    if ( $line =~ /\-\-\-\-/ ) {
		last if ( $wrote_copyright );
		$tex_string .= "\n\\noindent{\\bf About:}\n"; 
		$wrote_copyright = 1;
		next;
	    }
	    if ( $line =~ /\-!\-/ ) {
		$line =~ /\-!\-\s*(.+?)\:/;
		$comment_name = $1;
		$skip = ( $comment_name =~ /interaction/i );
		$line =~ s/\-!\-//; 
		$line =~ s/$comment_name\://;
		$comment_name = "\u\L$comment_name";
		$tex_string .= "\n\\noindent{\\bf $comment_name:}\n";  
	    }
	    next if ($skip);
	    $line =~ s/CC//; 
	    $line =~ s/_/ /g;
	    $tex_string .=  "$line\n"; 
	}  
    } 
    $tex_string =~ s/\&/\\\&/g;
    return $tex_string;
 
}

################################################
sub pdb_intro_text (@) {
    my ( $intro_section, $emphasis, $pdb_id, $pdb_descr) = @_;
    my $tex_string = "";
    my ($line, @lines);
    my ($file, $fh);
    my ($title, $compound, $source);
    my ($blah, $os, @aux);
    my ($writing_title, $writing_os, $writing_compound);

    printf "\t\t PDB intro text\n";

    $mentioned{$pdb_id} = 1;

    @lines = split '\n', $pdb_descr;
    $writing_title =  $writing_os = $writing_compound = 0;
    $os = $title = $compound = $source  ="";
    $nmr = 0;
    foreach $line ( @lines ) {
	$line = substr $line, 0, 70;
	if  ( $line =~ /ORGANISM_SCIENTIFIC/ ) {
	    ( $blah, $os) = split '\:',$line;
	    $os = lc $os;
	   
	} elsif  ( $line =~ /^TITLE\s*(\w.+)/ ) {
	    if ( ! $writing_title ) {
		$writing_title = 1;
		$title = lc $1;
	    } else {
		@aux = split " ", $1;
		shift @aux; # get rid of continuation number;
		$title .= " ";
		$title .= lc join " ", @aux;
	    }
	} elsif ( $line =~  /^COMPND \s*(\w.+)/ ) {
	    if ( ! $writing_compound ) {
		$writing_compound = 1;
		$compound = lc $1;
	    } else {
		@aux = split " ", $1;
		shift @aux; # get rid of continuation number; 
		$compound .= " ";
		$compound .= lc join " ", @aux;
	    }
	} elsif ( $line =~  /^SOURCE \s*(\w.+)/ ) {
	    $source = lc $1;
	} elsif ( $line =~  /^EXPDTA/ ) {
	    ($line =~ /NMR/) && ($nmr = 1);
	} 
    } 
    
    if  ($title || $os || $compound || $source) {
	
	($intro_section ) && ( $tex_string  = "\\section\{Introduction\}\n");
	$tex_string .= "\nFrom the original Protein Data Bank entry (PDB id $pdb_id):\n\n";
	if ( $title) {
	    $title =~ s/_/ /g;  $title =~ s/\$//g;
	    if ( $emphasis ) {
		$tex_string .= "\n\\noindent{\\bf Title:} \u$title\n" ;
	    } else {
		$tex_string .= " Title: \u$title\n" ;
	    }
	}
	if ( $compound) {
	    $compound =~ s/_/ /g; $compound =~ s/\$//g;
	    
	    if ( $emphasis ) {
		$tex_string .= "\n\\noindent{\\bf Compound:} \u$compound\n" ;
	    } else {
		$tex_string .= " Compound: \u$compound\n" ;
	    }
	}  
	if ($os) {
	    $os =~ s/_/ /g; $os  =~ s/\$//g;
	    @aux = split " ", $os;
	    if ( $emphasis ) {
		$tex_string .= "\n\\noindent{\\bf Organism, scientific name:}  ";  
	    } else {
		$tex_string .= " Organism, scientific name:  ";  
	    }
	    foreach (@aux ) {
		$tex_string .= " \u$_";
	    }
	    $tex_string .= "\n";
	} elsif ( $source) {
	    $source =~ s/_/ /g; $source =~  s/\$//g;
	    if ( $emphasis ) {
		$tex_string .= "\n\\noindent{\\bf Source:} \u$source\n";
	    } else {
			$tex_string .= " Source: \u$source\n";
	    }
	}
    } else {
	printf "\t\tno intro field found in pdb\n";
    }

    $tex_string =~ s/\&/\\\&/g;
    $tex_string =~ s/\#/\\\#/g;
    return $tex_string;
}

#######################################################################
sub pdb_chain_comment(@) {
    my $pdb_id = shift @_;
    my @not_enough_seqs_chains = @_;
    my ($chain, $copy);
    my $tex_string;
    my ($file, $fh, $ctr);
    my @peptides = ();
    my @aux;

    $tex_string = "";
    $tex_string .= "\n $pdb_id contains ";
    if ( @unique_chains < 2 ) {
	$chain = $unique_chains[0];
	$tex_string .= " a single unique chain $chain ";
	$tex_string .=  " (". (length $sequence{$chain})." residues long)"; 
	if (defined @{$copies{$chain}}  &&  @{$copies{$chain}}) {
	    if ( @{$copies{$chain}} < 2 ) {
		$copy = $copies{$chain}[0];
		$tex_string .= " and its homologue $copy.\n";
	    } else {
		$tex_string .= " and its homologues ";
		$tex_string .=  this_and_that (@{$copies{$chain}}).".\n";
	    } 
	} else {
	    $tex_string .= ". \n";
	}
    } else {
	@aux = ();
	foreach $chain ( @unique_chains ) {
	    push @aux, $chain. " (". (length $sequence{$chain})." residues)";
	}
	$tex_string .= " unique  chains ". this_and_that ( @aux)."\n";
	foreach $chain ( @unique_chains ) {
	    if ( defined $copies{$chain} && @{$copies{$chain}} ) {
		$tex_string .= "  ";
		if (  @{$copies{$chain}} < 2 ) {
		    $tex_string .= $copies{$chain}[0]." is a homologue of chain $chain.\n";
		} else {
		    $tex_string .= this_and_that (  @{$copies{$chain}} )." are homologues of chain $chain.\n";
		}
	    }
	}

    }
    
    foreach $chain ( @{$ligands{$pdb_id}} ) {
	( $is_peptide{$chain} ) && push @peptides, $chain;
    }
    if ( @peptides ) {
	if ( @peptides < 2 ) {
	    $chain = $peptides[0];
	    $tex_string .= " Chain $chain is too short   (".(length $sequence{$chain}) ." residues)"; 
	    $tex_string .= " to permit statistically significant analysis, and was treated as a peptide ligand.\n"; 
	} else {
	    $tex_string .= " Chains ". this_and_that ( @peptides )." are too short";
	    $tex_string .= " to permit statistically significant analysis, and were treated as a peptide ligands.\n"; 
	}
    }
    
    if ( @not_enough_seqs_chains ) {
	$tex_string .= " Not enough homologous sequences could be found to permit analysis for ";
	if ( @not_enough_seqs_chains < 2 ) {
	    $tex_string .=  " chain $not_enough_seqs_chains[0].\n";
	} else {
	    $tex_string .=  " chains ". this_and_that ( @not_enough_seqs_chains )."\n";
	}
    }
    
    if ( $nmr ) {
	$tex_string .= "This is an NMR-determined structure -- in this report the first model in the file was used.\n";
    }
    $file = "intro_comment.tex";
    $fh = outopen ($file); 
    print $fh  $tex_string;
    $fh->close;
    `mv $file $home/texfiles`;

    for ($ctr=0; $ctr < @texfiles; $ctr++ ) {
	if ( $texfiles[$ctr] eq "intro.tex") {
	    splice @texfiles, $ctr + 1, 0, $file;
	    last;
	}
    }
   

} 
#######################################################################
sub table_header (@) {
    my ($format, $label, $caption, @header_fields) = @_;

    my $number_of_fields = $#header_fields + 1;
    my $table_header = "";
    my $retstring = "";
    my $ctr;
    my $title;
    my $need_another_line;
    my @aux;

    $need_another_line = 1;
    while ( $need_another_line ) {
	$need_another_line = 0;
	for $ctr ( 0.. $#header_fields) {
	    if ( $header_fields[$ctr] =~ /\S/ ) {
		@aux = split " ", $header_fields[$ctr];
		( @aux > 1 ) && ($need_another_line = 1);
		$title = shift @aux;
		$header_fields[$ctr] = join " ", @aux;
	    } else {
		$title = "";
	    }
	    ($ctr ) && ($table_header .= "  & ");
	    $table_header .= "   \{\\bf $title \}  ";
	}
	$table_header .= "      \\\\  \n";
    }
    $table_header .= " \\hline\n";

    $retstring  .= "%\n%\n\\begin{center} \n";

    $retstring  .= "\\tablefirsthead {\n";
    $retstring  .= "\\hline\n\\multicolumn\{$number_of_fields\}\{|c|\}\{\\bf Table \\ref\{$label\}.}\\\\\n\\hline\n";
    $retstring  .= "$table_header\}\n";
   # $retstring  .= "\\tablehead {\\hline\\\\\n$table_header\}\n";

    $retstring  .= "\\tablehead {\n";
    $retstring  .= "\\hline\n\\multicolumn\{$number_of_fields\}\{|l|\}\{";
    $retstring  .= "\\bf Table \\ref\{$label\}. {\\small\\sl continued\}\}\\\\\n\\hline\n";
    $retstring  .= "$table_header\}\n";

    $retstring  .= "\\tabletail{\n";
    $retstring  .= "\\hline\n";
    $retstring  .= "\\multicolumn\{$number_of_fields\}\{|r|\}\{\\small\\sl continued in next column}\\\\\n";
    $retstring  .= "\\hline\n\}\n";
    $retstring  .= "\\tablelasttail\{\\hline\}\n";
    $retstring  .=  "\\bottomcaption\{\\label\{$label\}\\rm $caption\}\n";
    $retstring  .=  "\{\\tt\n\\begin{supertabular}\{$format\} \n";



    return $retstring;
} 
#######################################################################
sub table_tail (@) {
     my  $retstring =  "\\end\{supertabular\}\n\}\n\\end\{center\}  \n\\vspace\{3mm\}\n";

    return $retstring;

}
#######################################################################
sub  annotation_shorthand ( @ ) {
    my $annotation_long = $_[0];
    my $annotation_short = "";
    if ( $annotation_long =~ /site/i ) {
	 $annotation_short = "site";
    } elsif ( $annotation_long =~ /salt/i ){
	$annotation_short = "sb";
    } elsif ( $annotation_long =~ /hydrogen/i ){
	$annotation_short = "hb";
    } elsif ( $annotation_long =~ /disul/i ){
	$annotation_short = "S-S";
    }
    return $annotation_short;
}
#################################################################################

sub mutation_table_if (@) {

    # uses $chain variable from the main program
    my ($name, $binding_partner, $min_dist_cvg,  $ref, $interface_entry) = @_;
    my @lines;
    my (@epitope , @epitope_sorted ) ;
    my %distance = ();
    my %noc      = ();
    my %noc_bb   = ();
    my ($aa, $nc, $bb, $min_dist);
    my ($commandline, $tex_string);
    my ($exists_annotation, $number_above_cutoff,$residue );
    my ($resctr,  $caption, $ref_mut, $last_ref);
    my $current_coverage = int (100*$min_dist_cvg);
    my (@aux, @substitutions, $subs, $ctr, $table_ctr);
    my ($format, @header_fields, $note);
    my ($index, $qry_aa_type);

    @epitope  = ();
    @epitope_sorted = ();
    @lines = split "\n", $interface_entry;
    foreach ( @lines) {
	my $id;
	next if (/^\#/ );
	($id, $aa, $nc, $bb, $min_dist) = split;
	push @epitope, $id;
	$distance{$id} = sprintf "%.2f",$min_dist;
	$noc{$id} = $nc;
	$noc_bb{$id} = $bb;
    }
       
    ( ! @epitope ) && return "";

    # sort epitope by cvg 
    @epitope_sorted = sort { $cvg{$name}{$a} <=> $cvg{$name}{$b} } ( @epitope );

    # figure out if exists annotation for any of the residues involved
    $exists_annotation = 0;
    $number_above_cutoff = 0;
    foreach $residue (@epitope_sorted) {
	next if ( $cvg{$name}{$residue}  > $max_cvg);
	$number_above_cutoff ++;
	if ( defined $annotation{$name}{$residue} ) {
	    $exists_annotation = 1;
	}
    }
    $number_above_cutoff || return "";

    $tex_string = "";
    $ref_mut = $ref."mut";

    # table production

    $caption   = " The top $current_coverage\\% of residues in $name at the interface with ";
    if ( defined $hetero{$binding_partner} ) {
	if ( defined  $chem_name{$hetero{$binding_partner}} ) {
	    $caption .=  $chem_name{$hetero{$binding_partner}}."." ;
	} else {
	    $caption .=  $hetero{$binding_partner}."." ;
	}
    } else {
	$caption  .= "  $binding_partner.\n"; 
    }
    $caption .=  "(Field names: res: residue number in the PDB entry;  type: amino acid type;";
    $caption .=  " substs: substitutions seen in the alignment, with the percentage of each type in the bracket;";
    $caption .=  " noc/bb: number of contacts with the ligand, with the number of contacts realized through ";
    $caption .=  " backbone atoms given in the bracket; dist: distance of closest apporach to the ligand. ";
    if ( defined $pid{$name} && $pid{$name} < 100 ) {
	$caption .= "  \"Res\" and \"type\" columns refer to numbering and type in $name, "; 
	$caption .= " while \"qry res\" refers to residue number and type in $id."; 
    }  
    $caption .=  ")\n";
    # text
    $tex_string  .= "Table \\ref\{$ref\} lists ";
    $tex_string  .= "the top $current_coverage\\% of residues  at the interface with $binding_partner";
    ( defined $hetero{$binding_partner} && defined $chem_name{$hetero{$binding_partner}}) 
	&&  ( $tex_string  .= " (". lc $chem_name{$hetero{$binding_partner}}.")" );
    $tex_string  .= ". ";  
    $tex_string  .= "The following table (Table \\ref\{$ref_mut\})  suggests possible";
    $tex_string  .= " disruptive replacements for these residues (see Section \\ref{mutnotes}).\n";

    if ( defined $pid{$name} && $pid{$name} < 100 ) {
	$format =  "r|c|c|";
	@header_fields = ( "res", "model type",  "qry res");
    } else {
	$format =  "r|c|";
	@header_fields = ( "res", "type");
    }
    if ( $exists_annotation ) { 
	$format .= "l|r|r|r|l",
	push  @header_fields, (  "subst's (\\%)",  
			    "cvg ",  "noc/ bb", "dist (\$\\AA\$)",  " antn"); 
    } else {
	$format .= "l|r|r|r";
       	push  @header_fields, (  "subst's (\\%)",  
			    "cvg ",  "noc/ bb", "dist (\$\\AA\$)" ); 
    }

    $tex_string  .= table_header ( $format, $ref, $caption, @header_fields);

    $resctr    = 0;
    $table_ctr = 0;
    foreach $residue  (@epitope_sorted) { 
	next if ( $cvg{$name}{$residue}  > $max_cvg); 

	@aux = split '',  $subst{$name}{$residue}; 
	@substitutions = ();
	$subs = "";
	$ctr = 1;
	foreach $aa ( @aux ) {
	    # if substitution appears in < 1% of cases, it is  not listed
	    (  defined $aa_freqs{$name}{$residue}{$aa} ) &&  ($aa .= "(".$aa_freqs{$name}{$residue}{$aa}.")");
	    if ( (length $subs) + (length $aa) <= 7 ) {
		$subs .= $aa;
	    } else {
		push @substitutions, $subs;
		$subs = $aa;
	    }
	    $ctr++;
	}
	($subs) &&  (push @substitutions, $subs);
	if ( defined $pid{$name} && $pid{$name} < 100 ) {
	    $index = $sequential{$name}{$residue};
	    if ( defined $map_on_qry{$name}[$index] ) {
		$index = $sequential{$name}{$residue};
		$qry_aa_type =  $map_on_qry{$name}[$index];
	    } else {
		$qry_aa_type = "-";
	    }
	    $tex_string  .=  "$residue &   $type{$name}{$residue}  & $qry_aa_type &  $substitutions[0]    ";
	} else {
	    $tex_string  .=  "$residue &  $type{$name}{$residue}  &  $substitutions[0]    ";
	}
	$tex_string  .=  "  &   $cvg{$name}{$residue}  &  $noc{$residue}/$noc_bb{$residue}  ";
	$tex_string  .=  "  &  $distance{$residue}   ";
	if ( $exists_annotation ) {
	    if ( defined  $annotation{$name}{$residue} ) {
		$note = annotation_shorthand ($annotation{$name}{$residue}[0]);
		$tex_string  .=  " & $note  ";
	    } else {
		$tex_string  .=  " &   ";
	    }
	}
       
	$tex_string  .=  "\\\\";
	$tex_string  .=  "\n";
	shift @substitutions;
	for $subs ( @substitutions ) { # this line was too long
	    if ( defined $pid{$name} && $pid{$name} < 100 ) {
		$tex_string  .=  "  &  &   &  $subs   &   &   ";
	    } else {
		$tex_string  .=  "  &  &  $subs   &    &  ";
	    }
	    ( $exists_annotation )  && 	($tex_string  .=  " &   ");
	    $tex_string  .=  "\\\\";
	    $tex_string  .=  "\n";
	}
	$resctr++;
    }
    $tex_string  .=  table_tail(); 



    # disruptive mutations: 
    $resctr = 0;
    $table_ctr = 0;
    $caption   = " List of disruptive mutations for the top $current_coverage\\% of residues in $name, that are  at the interface with "; 
    if ( defined $hetero{$binding_partner} && defined $chem_name{$hetero{$binding_partner}} ) {
	$caption .=   $chem_name{$hetero{$binding_partner}}.".";
    } else {
	$caption  .= "  $binding_partner.\n"; 
    }


    $format =  "r|c|l";
    @header_fields = ("res", "type", "disruptive mutations");
    $tex_string  .= table_header ( $format, $ref_mut, $caption, @header_fields);

    my $suggestion;

    foreach $residue (@epitope_sorted) {
	next if ( $cvg{$name}{$residue}  > $max_cvg);
	$commandline = $path{"suggest"}."  $type{$name}{$residue}  $subst{$name}{$residue}";
	$suggestion = "" || `$commandline`;
	chomp $suggestion;
	$tex_string  .=  "$residue &  $type{$name}{$residue} & $suggestion  ";
	$tex_string  .=  "\\\\";
	$tex_string  .=  "\n";
	$resctr++;
    }
    $tex_string  .=  table_tail(); 
    # text


    return $tex_string;

}
#################################################################################

sub mutation_table_surf (@) {
    my ($name, $ref, $cluster) = @_;
    my @epitope_sorted;
    my ($exists_annotation, $number_above_cutoff, $residue);
    my ($resctr, $ref_mut, $tex_string,  $caption);
    my (@aux, @substitutions, $subs, $aa, $ctr);
    my ($commandline, $suggestion);
    my ($format, @header_fields, $note);
    my ($index, $qry_aa_type);

    # sort epitope by cvg
    @aux = split "_", $cluster;
    for  ( $ctr=$#aux; $ctr >= 0; $ctr-- ) {
	next if ( $aux[$ctr] );
	splice @aux, $ctr, 1;
    } 
    @epitope_sorted = sort { $cvg{$name}{$a} <=> $cvg{$name}{$b} } @aux;

    # figure out if exists annotation for any of the residues involved
    $exists_annotation = 0;
    $number_above_cutoff = 0;
    foreach $residue (@epitope_sorted) {
	next if ( $cvg{$name}{$residue}  > $max_cvg);
	$number_above_cutoff ++;
	if ( defined $annotation{$name}{$residue} ) {
	    $exists_annotation = 1;
	}
    }
    $resctr = 0;

    $number_above_cutoff || return "";

    $tex_string   = "";
    $tex_string  .= " The residues belonging to this surface \"patch\" are listed in Table \\ref\{$ref\}, \n"; 
    $ref_mut = $ref."mut";
    $tex_string  .= " while Table \\ref\{$ref_mut\} suggests possible disruptive replacements ";
    $tex_string  .= "for these residues (see Section \\ref{mutnotes}).\n";
    $caption   = " Residues forming surface \"patch\" in  $name.";  
    if ( defined $pid{$name} && $pid{$name} < 100 ) {
	$caption .= " \"Res\" and \"type\" columns refer to numbering and type in $name, ";
	$caption .= " while \"qry res\" refers to residue number and type in $id.";
    } 

    if ( defined $pid{$name} && $pid{$name} < 100 ) {
	$format =  "r|c|c|";
	@header_fields = ( "res", "model type",  "qry res");
    } else {
	$format =  "r|c|";
	@header_fields = ( "res", "type");
    }
    if ( $exists_annotation ) {
	$format .=  "l|r|l";
	push @header_fields, ( "substitutions(\\%)",  "cvg ", " antn");
    } else {
	$format .=  "l|r";
	push @header_fields, ( "substitutions(\\%)",  "cvg ");
    }
    $tex_string  .= table_header ( $format, $ref, $caption, @header_fields);

    foreach $residue (@epitope_sorted) {
	next if ( $cvg{$name}{$residue}  > $max_cvg);
	@aux = split '', $subst{$name}{$residue}; 
	@substitutions = ();
	$subs = "";
	$ctr = 1;
	foreach $aa ( @aux ) {
	    # if substitution appears in < 1% of cases, it is  not listed
	    (  defined $aa_freqs{$name}{$residue}{$aa} ) &&  ($aa .= "(".$aa_freqs{$name}{$residue}{$aa}.")");
	    if ( (length $subs) + (length $aa) <= 15 ) {
		$subs .= $aa;
	    } else {
		push @substitutions, $subs;
		$subs = $aa;
	    }
	    $ctr++;
	}
	($subs) &&  (push @substitutions, $subs);
	if ( defined $pid{$name} && $pid{$name} < 100 ) {
	    $index = $sequential{$name}{$residue};
	    if ( defined $map_on_qry{$name}[$index] ) {
		$index = $sequential{$name}{$residue};
		$qry_aa_type =  $map_on_qry{$name}[$index];
	    } else {
		$qry_aa_type = "-";
	    }
	    $tex_string  .=  "$residue &   $type{$name}{$residue}  & $qry_aa_type &  $substitutions[0]    ";
	} else {
	    $tex_string  .=  "$residue &  $type{$name}{$residue}  &  $substitutions[0]    ";
	}
	$tex_string  .=  "  &   $cvg{$name}{$residue}   ";
	if ( $exists_annotation ) {
	    if ( defined  $annotation{$name}{$residue} ) {
		$note = annotation_shorthand ($annotation{$name}{$residue}[0]);
		$tex_string  .=  " & $note  ";
	    } else {
		$tex_string  .=  " &   ";
	    }
	}
	$tex_string  .=  "\\\\\n";
	shift @substitutions;
	for $subs ( @substitutions ) { # this line was too long
	    if ( defined $pid{$name} && $pid{$name} < 100 ) {
		$tex_string  .=  "  &  &   &  $subs   &   ";
	    } else {
		$tex_string  .=  "  &  &  $subs   &   ";
	    }
	    ( $exists_annotation )  && 	($tex_string  .=  " &   ");
	    $tex_string  .=  "\\\\\n";
	}
	$resctr++;
    }
    $tex_string  .=  table_tail (); 

    # disruptive mutations: 
    $resctr = 0;
    $caption   = " Disruptive mutations for the surface patch  in $name.\n"; 
    $format =  "r|c|l";
    @header_fields = ("res", "type", "disruptive mutations");
    $tex_string  .= table_header ( $format, $ref_mut, $caption, @header_fields);

    foreach $residue (@epitope_sorted) {
	next if ( $cvg{$name}{$residue}  > $max_cvg);
	$commandline = $path{"suggest"}."  $type{$name}{$residue}  $subst{$name}{$residue}";
	$suggestion = "" || `$commandline`;
	chomp $suggestion;
	$tex_string  .=  "$residue &  $type{$name}{$residue} & $suggestion  ";
	    $tex_string  .=  "\\\\\n";
	$resctr++;
    }

    $tex_string  .=  table_tail(); 


    return $tex_string;
}





#################################################################################



1;
