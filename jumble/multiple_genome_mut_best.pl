#! /usr/bin/perl -w
# currently the genomes are in 
# /afs/bii.a-star.edu.sg/dept/biomodel_design/Group/ivana/databases/ensembl

sub formatted_sequence ( @);

$human_genome_dir    = "/home/ivanam/databases/ensembl/mammals/homo_sapiens";
$genomedir    = "/home/ivanam/databases/ensembl/mammals";

$blast        = "/home/ivanam/downloads/blast-2.2.16/bin/blastall -p blastp";
$seq_retrieve = "/home/ivanam/downloads/blast-2.2.16/bin/fastacmd";

############################################

defined $ARGV[0]  ||
    die "Usage: $0  <list of species> <fasta_file>.\n".
    "(Note: the sequences in fasta are assumed to belong to human.)\n"; 

($specie_list, $fasta) =  @ARGV; 

############################################
open ( GL, "<$specie_list" ) ||
    die "Cno $specie_list: $!\n";

@species = ();
while ( <GL> ) {
    next if ( !/\S/);
    chomp;
    push @species, $_;
}

close GL;


############################################



@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

while ( <FASTA> ) {
    next if ( !/\S/);
    chomp;
    if (/^>\s*(.+)/ ) {
	$name = $1;
	push @names,$name;
	$sequence{$name} = "";
    } else  {
	s/\./\-/g;
	s/\#/\-/g;
	s/\s//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close FASTA;


###########################################

foreach $query ( keys %sequence ) {
    
    print "$query ... ";

    open ( TMP, ">$query.fasta") ||
	die "CNo $query.fasta: $!\n";

    print TMP ">$query\n";
    print TMP formatted_sequence($sequence{$query});
    print TMP "\n";

    close TMP;

    # find itself in the human genome
    $human_gene = "";
    $new_gene = "";
    for  $human_genome  ("$human_genome_dir/all", "$human_genome_dir/abinitio"){
	$cmd = "$blast -i $query.fasta -d $human_genome  -o $query.human.blastp -e 1.e-10 -m 8";
	(system $cmd) && die "Error running $cmd\n";

	open (TMP, "<$query.human.blastp") 
	    || die "Cno $query.human.blastp: $!\n";

	$human_gene = "";
	@human_transcripts = ();
	while ( $ret = <TMP> ) {
	    chomp $ret;
	    @field  = split " ", $ret;
	    next if (!$human_gene && $field[2] ne "100.00");

	    $hit = $field[1];
	    if ( $human_genome =~ /all/ ) {
		$ret = `grep $hit $human_genome_dir/all.hdrs`;
		$ret =~ /gene\:(\w+) /;
		$new_gene = $1;
	    } else {
		$ret = `grep $hit $human_genome_dir/abinitio.hdrs`;
		$ret =~ /chromosome\:([\.\:\w\-\_]+) /;
		$new_gene = $1;

	    }
	    #print "$1\n";
	    if (!$human_gene) {
		$human_gene = $new_gene;
	    } elsif ($human_gene ne $new_gene) {
		last;
	    }
	    push  @human_transcripts, $hit;
	}
	close TMP;
	last if @human_transcripts;
    }
    
    @human_transcripts || die "not in human genome\n" ;
    print " cooresponds to gene $human_gene and transcripts:\n", (join "\n",@human_transcripts), "\n\n";


 
    $human_db_names = join "_", @human_transcripts;

    # find homologues  in the other  genomes
    $dmp = "$query.homologues.fasta";
    (-e $dmp) && `rm $dmp`;
    `cat $query.fasta > $dmp`;
    for $g ( 0 .. $#species ) {
    
	print "------------------------------------------------\n";
	print "$species[$g]\n";
	$spec_short = join "_", ( map{substr $_,0, 3}(split "_", uc $species[$g] ) );

	$hom_found = 0;
	@homologue_genes = ();
	%seen = ();
	%chromosome = ();
	%used = ();
	%renamed = ();
	foreach $other_genome  ("$genomedir/$species[$g]/all", "$genomedir/$species[$g]/abinitio" ) {

	    $cmd = "$blast -i $query.fasta -d $other_genome -o  $query.$species[$g].blastp -e 1.e-5 -m 8";
	    (system $cmd) && die "Error running $cmd\n";
    
	    foreach $line ( split "\n", `cat $query.$species[$g].blastp`) {
		@field  = split " ", $line;
		
		$homologue = $field[1];
		( defined $seen{$homologue} ) && next;
		$seen{$homologue} = 1;

		`echo  $field[1] > name`;

		$cmd = "$seq_retrieve -d $other_genome -i name -o tmp.fasta";
		(system $cmd) && die "Error running $cmd\n";



		# mutual best hit
		$cmd = "$blast -i tmp.fasta -d $human_genome -o $query.$species[$g].mut.blastp".
		    " -e 1.e-5 -m 8";
		(system $cmd) && die "Error running $cmd\n";

		$ret = `grep $homologue $query.$species[$g].mut.blastp | head -n1`;
		next if ( !$ret);
		chomp $ret;
		@field  = split " ", $ret;
		if ( $human_db_names =~ $field[1] ) {
		    #  $query  and $homologue are mutual
		    $hom_found = 1;

		    # now collect the genes the putative homologues belong to
		    $gene = "";
		    $ret = `grep $homologue $other_genome.hdrs`;
		    $ret =~ /gene\:(\w+) /;
		    if ( defined $1 ) {
			$gene = $1;
			if ( ! defined $seen{$gene} ) {
			    $seen{$gene} = 1;
			    push @homologue_genes, $gene;
			    if ( $ret =~ /chromosome\:([\.\:\w\-\_]+) /) {
				$chromosome{$gene} = $1;
			    } elsif ( $ret =~ /scaffold\:([\.\:\w\-\_]+) /)   {
				$chromosome{$gene} = $1;
			    } elsif ( $ret =~ /contig\:([\.\:\w\-\_]+) /)   {
				$chromosome{$gene} = $1;
			    } else {
				$chromosome{$gene} = "";
			    }
			}
		    }
		    if ($gene) {
			print "  $homologue $gene \n";
		    } else {
			print "  $homologue\n";
		    }


		    # rename this seq
		    $new_name = $spec_short."_$query";
		    if ( defined $used{$new_name} ) {
			$used{$new_name}++;
			$new_name .= "_".$used{$new_name};
		    } else {
			$used{$new_name} = 1;
		    }

		    `echo \'>$new_name\' > tmp2.fasta`;
		    `grep -v \'>\' tmp.fasta >> tmp2.fasta`;
		    `mv tmp2.fasta tmp.fasta`;
		    `cat tmp.fasta >> $dmp`;
		    $renamed{$gene} = $new_name;

		}
	    }
	    if ( @homologue_genes ) {
		printf "genes: ";
		foreach $gene (@homologue_genes) {
		    print "\t $gene   $renamed{$gene}   $chromosome{$gene}\n";
		}
	    }
	    last if ($hom_found); # otherwise try the abinitio genome
	}  # end all/abinitio lop


    }# end loop over other genomes
}
######################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || 
	die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 
