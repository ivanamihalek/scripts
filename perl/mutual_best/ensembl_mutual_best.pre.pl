#! /usr/bin/perl

sub genome2name (@);
sub extract_first_seq (@);
sub find_by_blasting (@);
sub set_mammals ();

################################################
#  paths that need to be adjusted:
#
$blast    = "/usr/bin/blastall";
$fastacmd = "/usr/bin/fastacmd";
$mafft    = "/usr/local/bin/mafft";

$db_path = "/home/ivanam/databases/ensembl_pre";
$home = `pwd`;
chomp $home;

################################################
#  input negotiation
#
(@ARGV >= 3) || 
    die "Usage: $0 <input seq file>  ".
    "<descr file (output)> <fasta file (output)> [<name tag>] \n";

($seqfile,  $descrfile, $fastafile)  =  @ARGV;
$name_tag = "";
(@ARGV > 3) && ($name_tag = $ARGV[3]);

$orig_genome  = "/mnt/ensembl/release-67/fasta/homo_sapiens/pep/Homo_sapiens.GRCh37.67.pep.all.fa" ;
(-e $orig_genome)  || die " $orig_genome not found\n";


################################################
#  check if we have everything that we need
#
foreach ($seqfile, $blast, $fastacmd, $mafft, $db_path) {
    (-e $_) || die "$_ not found.\n";
}

$blast .= " -p blastp -e 1.e-2 -m 8 -a 4"; # m 8 = output in a tabular format; a 4 = 4 cpus


################################################
#  output files
#
for ($descrfile, $fastafile) {
    print $_, "\n";
    open ($fh{$_}, ">$_") ||
	die "Cno $_: $!.\n";
}

if ( $name_tag ) {
    $logfile = "ensembl_$name_tag.log";
} else {
    $logfile = "ensembl.log";
}
open (LOG, ">$logfile") || die "Cno $logfile: $!.\n";
open (ERR, ">errlog")   || die "Cno errlog: $!.\n";

##################################################################
#  find the  query sequence in the "original" genome (together
#  with the  gene/protein/trnascript entry it belongs to)
#
$outfile    = "tmp.fasta";
@orig_search_ids = ();
@orig_search_ids = find_by_blasting($orig_genome, $seqfile, $blast, $outfile);
if  (! @orig_search_ids) {
    `rm -f tmp*`;
     print ERR "$seqfile does not exist in $orig_genome_known";
     die "\n";
}

print LOG "the closest match to $seqfile in  $orig_genome is $orig_search_ids[0]\n";

($orig_protein, $orig_gene_name, $orig_transcript, $orig_gene_location) = split " ", $orig_search_ids[0];

print LOG "$seqfile id in $orig_genome: $orig_protein\n";
print LOG "gene name in $orig_genome:   $orig_gene_name\n";

$orig_seq_file = "orig_seq.fasta";
extract_first_seq ($outfile, $orig_protein, $orig_seq_file);

`rm -f tmp*`;

##################################################################
#  blast the query sequence against all of the remaining genomes
#
chdir $db_path;
@genomes = split "\n", `ls `;
chdir $home;

GENOME:
foreach $genome (@genomes ) {

    print $genome, "\n";

    #       forward search
    #
    print LOG "\n$genome\n";
    $found = 0;

    $outfile    = "tmp.fasta";

    chdir $db_path;
    chdir $genome;
    $genome_fa   =  `ls *.fa`; chomp $genome_fa;
    $genome_file = "$db_path/$genome/$genome_fa";

    chdir $home;
    (-e $genome_file) || die "$genome_file not found\n";

    @forward_ids = find_by_blasting($genome_file, $orig_seq_file, $blast, $outfile);


    if (!@forward_ids ) {
	print LOG "$seqfile not found in $genome, \"known\" sequences\n";

    } else {

	# lif we found something, we still need to check if it is mutual best
	print LOG "best forward hit:  $forward_ids[0]  \n";

	($protein, $gene_name, $transcript, $gene_location) = split " ", $forward_ids[0];
	extract_first_seq ($outfile, $protein, "$genome.fasta");
    

	#       back search
	#
	@back_ids = find_by_blasting ($orig_genome, "$genome.fasta", $blast, $outfile); 
	if (!@back_ids ){
	    print LOG "\t reciprocal search in $orig_genome using $genome as a query produced no hits (?)\n";
	    print LOG "*****************************************\n\n";
	    `rm $genome.fasta`;
	    next GENOME;
	} 

	# check whether back search retrieves the original query
	# three possibilities here
	# 1) the first hit is the original gene ==> this is the mutual best hit
	# 2) the original gene does not appear on the list -- we take there is no ortohologue in this specie
	# 3) the original gene is somewhere down the list  -- for now take that it also means "orthologue not found"

	($back_protein, $back_gene_name, $back_transcript, $back_gene_location) = split " ", $back_ids[0];

	# if the back gene is the same as the original one, we are done
	# otherwise, go and check in the "ab initio" detected list


	if ( $back_gene_name eq  $orig_gene_name) {
	    print LOG "\t best mutual hit:  $gene_name  $protein\n";
	    $found = 1;
	} else {
	    print LOG "\t back search returns  $back_gene_name as the best hit\n";
	    print LOG "\t no mutual best found in known -- try ab initio \n";
	}
    }
    
 

    print LOG "*****************************************\n\n";

    if ( !$found) {
	`rm $genome.fasta`;
	next;
    }


    $sequence =  `cat $genome.fasta`;
    @lines     = split "\n", $sequence;
    $spec_name = genome2name ($genome);

    if ( defined $seen{$spec_name} ) {
	print LOG  "name $spec_name appears twice in $genome\n\n";
	`rm $genome.fasta`;
	next;

    } else {
	$seen{$spec_name} = 1;
    }


    print {$fh{$descrfile}} "$genome\n";
    print {$fh{$descrfile}} "$forward_hit_descr   $spec_name\n";

    print {$fh{$descrfile}}  shift  @lines;
    print {$fh{$descrfile}} "\n\n";

    unshift @lines, ">$spec_name";
    print {$fh{$fastafile}} join "\n", @lines;
    print {$fh{$fastafile}} "\n";

    print  "$fastafile: >$spec_name\n";


    `rm $genome.fasta`;
}


`rm tmp_blastout  tmp.fasta  tmp_ids`;

for ($descrfile, $fastafile) {
    close $fh{$_};
}

print LOG  "not found:\n\n";

foreach (@not_found) {
    print LOG   "\t$_\n";
    print LOG   "\tknown\n";
    foreach $hit ( @{$forward_ids{$_}} ) {
	print LOG   "\t\t $hit\n";
    }
    print LOG   "\tab initio\n";
    foreach $hit ( @{$ab_init_forward_ids{$_}} ) {
	print LOG   "\t\t $hit\n";
    }
    print  LOG  "\n\n";

}


###############################
###############################
#  align


$afafile = $fastafile;
$afafile =~  s/\.fasta/.mafft.afa/;
$cmd = "$mafft --quiet $fastafile > $afafile";
if (system $cmd) {
    print ERR "Error running $cmd.\n";
    die "\n";
}


###############################
###############################

sub find_by_blasting (@) {

    my($genome_file, $seqfile, $blast, $temp_seq_file_name) = @_;
    my $cmd;

    $cmd = "$blast -d $genome_file -i $seqfile -o tmp_blastout"; #| head -n 10 | awk \'{print \$2}\' > tmp_ids ";
    if (system $cmd) {
	print ERR  "Error running $cmd.\n";
	die "\n";
    }

    if ( -z "tmp_blastout" ) {
	`rm tmp_blastout`;
	return ();
    }

    `head -n 10 tmp_blastout | awk \'{print \$2}\' > tmp_ids`;
    $cmd = "$fastacmd -d $genome_file -i tmp_ids > $temp_seq_file_name";
    if (system $cmd) {
	print ERR "Error running $cmd.\n";
	die "\n";
    }



    #`rm tmp_blastout  tmp_ids`;

    my @headers = split "\n", `grep \'>\' $temp_seq_file_name`;
    my @ids = ();

    foreach $hdr (@headers) {
	# parse header
	
	$hdr =~ s/>//;
	$hdr =~ s/\|/:/;

	$parsed = 1;
	my ($protein, $gene, $transcript, $location, $novelty) = ("","","","","");

	foreach  my $field ( split " ", $hdr) {
	    my @aux = split '\:', $field;

	    if ( $aux[0] eq "lcl" ) {
		$protein = $aux[1];

	    } elsif ( $aux[0] eq "gene" ) {
		$gene = $aux[1];

	    } elsif ( $aux[0] eq "transcript" ) {
		$transcript    = $aux[1];

	    } elsif ( $aux[0] eq "pep" ) {
		$novelty = $aux[1];

	    } elsif ( $aux[0] =~ "biotype" ) { # protein coding or not - I don't hink I need it

	    } elsif ( ! $location) {
		$location = $field;
	    } else {
		$parsed = 0;
		last;
	    }
	}
	if (! $parsed) { 

	    if ($hdr =~ /(ENS\w\w\wP0\w+)/) {
		$protein =  $1;
	    } elsif ($hdr =~ /(ENSP\w+)/) {
		$protein =  $1;
	    } elsif ($hdr =~ /lcl\:(\S+)/) {
		$protein =  $1;
	    } else {
		print ERR "unrecognized header format:\n$hdr ";
		die "\n";
	    }
	}

	push @ids, "$protein $gene $transcript  $location  $novelty"; # $novelty says "novel" or "known"
	#print "$hdr\n   $protein $gene $transcript $location $novelty\n";

	
    }

    return @ids;
}


sub genome2name (@) {
    my $genome = $_[0];
    my @aux = split "_", $genome;
    my $name;
 
    $name = uc join "_", map { substr ($_, 0, 3) }  @aux[0..1];
    ($name_tag) && ( $name .= "_$name_tag");

    return $name;
}

##################################################################3
sub extract_first_seq (@) {
    my ($infile, $name, $outfile) = @_;
    my $reading;
    open (OF , ">$outfile") || die "Cno $outfile:$!\n";
    # would it be better to use the longest transcript here, instead
    # of the first hit?
    $reading = 0;
    foreach (split "\n", `cat  $infile`) {
	next if ( !/\S/);
	if ( /^>/ ) {
	    $reading && last;
	    print OF ">$name\n";
	    $reading = 1;
	} else {
	    print OF $_;
	}
    }
    print OF "\n";
    close OF;
}


sub set_mammals () {

    #Primates
    push @mammals, lc "Homo_sapiens";
    push @mammals, lc "Pan_troglodytes";
    push @mammals, lc "Gorilla_gorilla";
    push @mammals, lc "Pongo_abelii";
    push @mammals, lc "Nomascus_leucogenys";
    push @mammals, lc "Macaca_mulatta";
    push @mammals, lc "Otolemur_garnettii";
    push @mammals, lc "Callithrix_jacchus";

    push @mammals, lc "Microcebus_murinus";
    push @mammals, lc "Tarsius_syrichta";

    #Rodents etc.
    push @mammals, lc "Mus_musculus";
    push @mammals, lc "Rattus_norvegicus";
    push @mammals, lc "Cavia_porcellus";
    push @mammals, lc "Dipodomys_ordii";
    push @mammals, lc "Ochotona_princeps";
    push @mammals, lc "Oryctolagus_cuniculus";
    push @mammals, lc "Spermophilus_tridecemlineatus";
    push @mammals, lc "Tupaia_belangeri";

    #Laurasiatheria
    # Cetartiodactyla (whales, dolphins, hippos, ruminants, pigs, camels etc.)
    push @mammals, lc "Bos_taurus";
    push @mammals, lc "Sus_scrofa";
    push @mammals, lc "Vicugna_pacos";
    push @mammals, lc "Tursiops_truncatus";
    # carnivores
    push @mammals, lc "Felis_catus";
    push @mammals, lc "Canis_familiaris";
    push @mammals, lc "Ailuropoda_melanoleuca";
    
    # Insectivora (hedgehogs, shrews, moles and others)
    push @mammals, lc "Erinaceus_europaeus";
    push @mammals, lc "Sorex_araneus";

    #Perissodactyla (horses, rhinos, tapirs)
    push @mammals, lc "Equus_caballus";

    # Chiroptera (bats)
    push @mammals, lc "Pteropus_vampyrus";
    push @mammals, lc "Myotis_lucifugus";

    #Afrotheria
    push @mammals, lc "Loxodonta_africana";
    push @mammals, lc "Procavia_capensis";
    push @mammals, lc "Echinops_telfairi";

    #Xenarthra
    push @mammals, lc "Dasypus_novemcinctus";
    push @mammals, lc "Choloepus_hoffmanni";

    #Other mammals
    push @mammals, lc "Monodelphis_domestica";
    push @mammals, lc "Ornithorhynchus_anatinus";
    push @mammals, lc "Sarcophilus_harrisii";

    push @mammals, lc "Macropus_eugenii";

}

sub set_vertibrates () {

    #Birds
    push @vertibrates, lc "Taeniopygia_guttata";
    push @vertibrates, lc "Gallus_gallus";
    push @vertibrates, lc "Meleagris_gallopavo";

    #Reptiles
    push @vertibrates, lc "Anolis_carolinensis";

    #Amphibians
    push @vertibrates, lc "Xenopus_tropicalis";

    #Fish
    push @vertibrates, lc "Tetraodon_nigroviridis";
    push @vertibrates, lc "Takifugu_rubripes";
    push @vertibrates, lc "Gasterosteus_aculeatus";
    push @vertibrates, lc "Oryzias_latipes";
#    push @vertibrates, lc "Danio_rerio"; # Zebrafish doesn't work!

    #Lampreys
    push @vertibrates, lc "Petromyzon_Marinus";

}
