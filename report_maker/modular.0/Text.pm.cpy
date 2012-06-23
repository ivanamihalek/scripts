#!/usr/bin/perl -w 

use strict;
use Figures;
use Report_utils;

our ($id, $id_type, $main_db_entry);
our @texfiles;
our @pics;
our (@attachments, %attachment_description);
our ($home);
our %path = ();
our $alistat_footnote;

sub sequence_description(@);

######################################
sub primary_seq_text(@){

    my ($name) = @_;
    my @figure_pieces = ();
    my ($msf_descr_string, $tex_string);
    my ($label, $label_base, $number_of_fig_pieces);
    my ($file, $numbers, $ctr, @aux);

    printf "\tprimary seq text\n";

    # sequence description
    $msf_descr_string = sequence_description ($name); # below
    # seq paint
    @figure_pieces = make_seq_portrait ($name); # in Figure.pm
    # table

    # text
    $tex_string  =  "";
    $tex_string .=  $msf_descr_string;
    $tex_string .=  "\\subsection {Residue ranking in $name}\n";
    # the text that goes with  the seqeunce figure
    $number_of_fig_pieces = $#figure_pieces +1;
    $label_base = "seqpaint$name"; 
    $tex_string  .= "The $name seqeunce is shown in "; 
    if ( @figure_pieces > 1 ) {
	$tex_string  .= " Figs. \\ref\{$label_base"."1\} -\\ref\{$label_base"."$number_of_fig_pieces\}, ";
    } else { 
	$label = $label_base."1";
	$tex_string  .= " Fig. \\ref\{$label_base"."1\}, ";
    } 
    $tex_string .= " with each residue colored according to its presumed importance.\n"; 

    for $ctr ( 1 .. $number_of_fig_pieces) { 
	$label = $label_base.$ctr;
	$tex_string  .= "\\begin\{figure\}  \{\n\\center\n";
	$file = $figure_pieces[$ctr-1];
	$tex_string  .= "\\includegraphics[width=80mm] {$file}\n";
	@aux = split '\.', $file; 
	pop @aux;
	$numbers =  pop @aux;
	$numbers =~ s/_/\-/;
	$tex_string  .= " \}\n \\caption\{\\label\{$label\} Residues  in $name, colored
                     by their relative importance. (The numbering is sequential.)} \n\\end\{figure\}\n";
    }
    $tex_string  .= "The full listing of residues in $name can be found in the file called $name.ranks\\_sorted ";
    $tex_string  .= " in  the attachment";
    push @attachments, "$name.ranks_sorted";
    $attachment_description{"$name.ranks_sorted"} = " full listing of residues and their ranking for $name";
    # if structure move on to structure 

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

    printf "\t\t sequence description\n";
    $no_seqs = `grep Name  $name.msf | wc -l`; chomp $no_seqs;
    ($ret, $almt_length) = split " ",  `grep \'MSF:\' $name.msf`;

    $msf_descr_string = "\\subsection\{Multiple sequence alignment for $name\}\n";
    $msf_descr_string .= "For the chain $name, the alignment $name.msf (attached) with $no_seqs sequences was used."; 
    push @attachments, "$name.msf"; 
    $attachment_description {"$name.msf"} = "the multiple sequence alignment used for the chain $name.\n";

    # alistat	
    $commandline = $path{"alistat"}." $name.msf | tail -n 12| head -n 11 ";
    $ret =  `$commandline`;
    ($ret) || die "$name: alistat failure.";
    $ret =~ s/\#/number of/g;

    $msf_descr_string .= " Its statistics, using \\emph{alistat} program is the following";
    if  (! $alistat_footnote ) { #footnote
	$alistat_footnote = 1;
	$msf_descr_string .= "\\footnote\{See Appendix for the explanation of the fields  and \\emph{alistat\}'s copyright statement\}";
    } 
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
    } elsif ( !  -e "$name.descr" || ! -s "$name.descr")  {
	$commandline = $path{"extract_descr"}." < $name.names > $name.descr ";
	(system $commandline) && die "Error extracting sequence description.";
    }
   
    #count species
    $msf_descr_string .= species("$name.descr", $no_seqs);
    
    $msf_descr_string .= "The file containing the sequence descriptions can be found in the attachment, under the name $name.descr.\n";
    push @attachments, "$name.descr"; 
    $attachment_description {"$name.descr"} = "description of sequences ued in $name msf.\n";

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
    # make appendix
    # list of files
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

    #print `cat $texlist`;
    ( -e "$id\_report.tex" ) && `rm  $id\_report.tex`;
    $command = "cat $texlist > $id\_report.tex";
    (system $command ) && die "Failure concatenating texfiles.";  
    $ret = `echo q | latex $id\_report.tex `; # to make the thing die if it gets stuck 
    ( $ret =~ /Output written on/ ) || die "$ret";
    if  ( $ret =~ /Rerun to get cross\-references right/ ) {
	$ret = `echo q | latex $id\_report.tex `;
	($ret =~ /Output written on/ ) || die "$ret";
    }

    print "dvi produced.\n";

    `xdvi $id\_report`; exit;

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
	$tex_string .= "From SwissProt, id $uniprot_id, $pct_identity\\% identical to $chain:\n\n";
    }
    $writing_os = $writing_oc = $writing_de = $wrote_copyright = $skip = 0;

    foreach $line ( @lines ) {
	if  ( $line =~ /^OS/ ) {
	    if ( ! $writing_os ) {
		$tex_string .= "\n{\\bf Organism, scientific name:}\n";  
		$writing_os = 1.0;
	    }
	    $line =~ s/OS//;
	    $tex_string .=  "$line\n";
	} elsif  ( $line =~ /^OC/ ) {
	    if ( ! $writing_oc ) {
		$tex_string .= "\n{\\bf Taxonomy:}\n";  
		$writing_oc = 1.0;
	    }
	    $line =~ s/OC//;
	    $tex_string .=  "$line\n";
	} elsif  ( $line =~ /^DE/ ) {
	    if ( ! $writing_de ) {
		$tex_string .= "\n{\\bf Description:}\n";  
		$writing_de = 1.0; 
	    }
	    $line =~ s/DE//; 
	    $tex_string .=  "$line\n" ;
	} elsif ( $line =~ /^CC/ ) {
	    if ( $line =~ /\-\-\-\-/ ) {
		last if ( $wrote_copyright );
		$tex_string .= "\n{\\bf About:}\n"; 
		$wrote_copyright = 1;
		next;
	    }
	    if ( $line =~ /\-!\-/ ) {
		$line =~ /\-!\-\s*(.+)\:/;
		$comment_name = $1;
		$skip = ( $comment_name =~ /interaction/i );
		$line =~ s/\-!\-//; 
		$line =~ s/$comment_name\://;
		$comment_name = "\u\L$comment_name";
		$tex_string .= "\n{\\bf $comment_name:}\n";  
	    }
	    next if ($skip);
	    $line =~ s/CC//; 
	    $tex_string .=  "$line\n"; 
	}  
    } 
    

    if ($file eq  "intro.tex" ) {
	chdir "$home/texfiles";
	$fh = outopen ($file);
	print $fh   $tex_string;
	$fh->close;
	chdir "$home";
	return "";
    } else {
	return $tex_string;
    }

}

################################################
sub pdb_intro_text (@) {

    my $pdb_id = $_[0];
    my $pdb_descr = $_[1];
    my $tex_string = "";
    my ($line, @lines);
    my ($file, $fh);
    my $title;
    my ($blah, $os, @aux);
    my ($writing_title, $writing_os);

    printf "\t\t PDB intro text\n";

    $tex_string  = "\\section\{Introduction\}\n";
    $tex_string .= "From the orginal Protein Data Bank entry (PDB id $pdb_id):\n\n";

    @lines = split '\n', $pdb_descr;
    $writing_title =  $writing_os = 0;
    foreach $line ( @lines ) {
	if  ( $line =~ /ORGANISM_SCIENTIFIC/ ) {
	    ( $blah, $os) = split '\:',$line;
	    $os = lc $os;
	    @aux = split " ", $os;
	    $tex_string .= "\n{\\bf Organism, scientific name:}  ";  
	    foreach (@aux ) {
		$tex_string .= "\u$_";
	    }
	    $tex_string .= "\n";
	   
	} elsif  ( $line =~ /TITLE\s*(\w.+)/ ) {
	    $title = lc $1;
	    if ( ! $writing_title ) {
		$tex_string .= "\n{\\bf Title:} \u$title\n"; 
		$writing_title = 1;
	    } else {
		$tex_string .=  "$title\n"; 
	    }
	}     
    } 
    

    $file = "intro.tex"; 
    chdir "$home/texfiles";
    $fh = outopen ($file);
    print $fh   $tex_string;
    $fh->close;
    chdir "$home";

    #push @texfiles, $file; this is a specail case - it is already on the txfile stack
}



1;
