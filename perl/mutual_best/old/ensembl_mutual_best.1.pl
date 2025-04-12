#! /usr/bin/perl

sub genome2name (@);
sub extract_first_seq (@);
sub find_by_blasting (@);

################################################
################################################
#
#  paths that need to be adjusted:
#
#
################################################
$blast    = "/usr/bin/blastall";
$fastacmd = "/usr/bin/fastacmd";

$genome_path        = "/afs/bii.a-star.edu.sg/dept/biomodel_design/Group/ivana/databases/ensembl/known/mammals";
$abinit_genome_path = "/afs/bii.a-star.edu.sg/dept/biomodel_design/Group/ivana/databases/ensembl/abinitio/mammals";

$all_list           = "$genome_path/species";
################################################
################################################




################################################
#  input negotiation
#
(@ARGV > 3) || 
    die "Usage: $0 <input seq file> <orig_genome>  ".
    "<descr file (output)> <fasta file (output)> [<name tag>] \n";

($seqfile, $orig_genome, $descrfile, $fastafile)  =  @ARGV;
$name_tag = "";
(@ARGV > 4) && ($name_tag = $ARGV[4]);



################################################
#  check if we have everything that we need
#
foreach ($seqfile, $genome_path, $abinit_genome_path, $all_list, 
	 $blast, $fastacmd, "$genome_path/$orig_genome", "$abinit_genome_path/$orig_genome") {
    (-e $_) || die "$_ not found.\n";
}


$blast .= " -p blastp -e 1.e-2  -m 8 "; # 8 == output in a tabular format

@genomes = split "\n", `cat $all_list`;


#@genomes = ("Ochotona_princeps");

################################################
#  output files
#
for ($descrfile, $fastafile) {
    open ($fh{$_}, ">$_") ||
	die "Cno $_: $!.\n";
}

if ( $name_tag ) {
    $logfile = "ensembl_$name_tag.log";
} else {
    $logfile = "ensembl.log";
}
open (LOG, ">$logfile") || die "Cno $logfile: $!.\n";


##################################################################
#  find the  query sequence in the "original" genome (together
#  with the  gene/protein/trnascript entry it belongs to)
#

$outfile    = "tmp.fasta";
@orig_search_ids = ();
@orig_search_ids = find_by_blasting("$genome_path/$orig_genome/$orig_genome", $seqfile, $blast, $outfile);
@orig_search_ids ||  die "$seqfile doesn't exist in $orig_genome";

print LOG "the closest match to $seqfile in  $orig_genome is $orig_search_ids[0]\n";


($orig_protein, $orig_gene_name, $orig_transcript, $orig_gene_location) = split " ", $orig_search_ids[0];

print LOG "$seqfile id in $orig_genome: $orig_protein\n";
print LOG "gene name in $orig_genome:   $orig_gene_name\n";

$orig_seq_file = "orig_seq.fasta";
extract_first_seq ($outfile, $orig_protein, $orig_seq_file);


##################################################################
#  blast the query sequence against all of the remaining genomes
#

@not_found = ();

GENOME:
foreach $genome (@genomes ) {


    #       forward search
    #
    print LOG "\n$genome\n";
    $found = 0;

    $outfile    = "tmp.fasta";
    @forward_ids = find_by_blasting("$genome_path/$genome/$genome", $orig_seq_file, $blast, $outfile);

    if (!@forward_ids ) {
	print LOG "$seqfile not found in $genome, \"known\" sequences\n";

    } else {

	# if we found something, we still need to check if it is mutual best
	print LOG "best forward hit:  $forward_ids[0]  \n";

	($protein, $gene_name, $transcript, $gene_location) = split " ", $forward_ids[0];
	extract_first_seq ($outfile, $protein, "$genome.fasta");
    

	#       back search
	#
	@back_ids = find_by_blasting ("$genome_path/$orig_genome/$orig_genome", "$genome.fasta", $blast, $outfile); 
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
    

    if ( !$found){

	# We didn't find the protein in the "known" set og genes, or it wasn the mutual best
	# Can we find it in the abinitio annotated genome?


	@ab_init_forward_ids = find_by_blasting("$abinit_genome_path/$genome/$genome", 
						$orig_seq_file, $blast, $outfile);

	if ( !@ab_init_forward_ids){

	    $found = 0;
	    push @not_found, $genome;
	    print LOG "\t\t$seqfile not found in $genome, \"ab initio\" sequences\n";

	} else {

	    ($protein, $gene_name, $transcript, $gene_location) = split " ", $ab_init_forward_ids[0];
	    extract_first_seq ($outfile, $protein, "$genome.fasta");
	   

	    # now back with this one
	    @ab_init_back_ids = find_by_blasting ("$genome_path/$orig_genome/$orig_genome", 
						     "$genome.fasta", $blast, $outfile); 
	    
	    ($back_protein, $back_gene_name, $back_transcript, $back_gene_location) = split " ", $ab_init_back_ids[0];
	    if ( $back_gene_name eq  $orig_gene_name) {
	
		$found = 1;
		print LOG "\t\t best mutual hit:  $gene_name  $protein\n";

	    } else {
		
		$found = 0;
		push @not_found, $genome;
		@{$forward_ids{$genome}} = @forward_ids;
		@{$ab_init_forward_ids{$genome}} = @ab_init_forward_ids;

		print LOG "\t\t no mutual best found in ab initio either\n";
	    }
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
# optional: sort and align
$sort   =  "/home/ivanam/perlscr/fasta_manip/sort_by_taxonomy.pl";
#$muscle =  "/homels -lrt/ivanam/downloads/muscle3.6_src/muscle";
$mafft =  "/usr/local/bin/mafft-linsi";

foreach ( $sort, $mafft) {
    (-e $_) || die "$_ not found.\n";
}


$cmd = "$sort $fastafile > tmp.fasta";
(system $cmd) && die "Error running $cmd.\n";
`mv tmp.fasta $fastafile`;

$afafile = $fastafile;
$afafile =~  s/\.fasta/.mafft.afa/;
#$cmd = "$muscle -stable -in $fastafile -out $afafile ";
$cmd = "$mafft --quiet $fastafile > $afafile";
(system $cmd) && die "Error running $cmd.\n";

############
#$cmd = "$sort $forward_fasta > tmp.fasta";
#(system $cmd) && die "Error running $cmd.\n";
#`mv tmp.fasta $forward_fasta`;

#$afafile = $forward_fasta;
#$afafile =~  s/\.fasta/.mafft.afa/;
#$cmd = "$muscle -stable -in $forward_fasta -out $afafile ";
#$cmd = "$mafft --quiet $forward_fasta > $afafile";
#(system $cmd) && die "Error running $cmd.\n";




###############################
###############################

sub find_by_blasting (@) {

    my($genome_file, $seqfile, $blast, $temp_seq_file_name) = @_;
    my $cmd;

    $cmd = "$blast -d $genome_file -i $seqfile -o tmp_blastout"; #| head -n 10 | awk \'{print \$2}\' > tmp_ids ";
    (system $cmd) && die "Error running $cmd.\n";

    if ( -z "tmp_blastout" ) {
	`rm tmp_blastout`;
	return ();
    }

    `head -n 10 tmp_blastout | awk \'{print \$2}\' > tmp_ids`;
    $cmd = "$fastacmd -d $genome_file -i tmp_ids > $temp_seq_file_name";
    (system $cmd) && die "Error running $cmd.\n";

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
	$parsed ||   die "unrecognized header format:\n$hdr ";

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
