#! /usr/bin/perl -w


#! /usr/bin/perl -w

(@ARGV >= 3) ||
    die "Usage:  $0 <seq file> <specie> <acceptable length fraction>\n";


($qry_seqfile, $qry_spc, $acceptable_fraction) = @ARGV;

(-e $qry_seqfile) ||  die "$qry_seqfile not found.\n";


$dbdir    = "/home/ivanam/databases/refseq_genomes";
$blast    = "/home/ivanam/downloads/blast-2.2.16/bin/blastall -p blastp";
$fastacmd = "/home/ivanam/downloads/blast-2.2.16/bin/fastacmd";
$gi_names = "/home/ivanam/perlscr/fasta_manip/gi_names.pl";
$muscle   = "/home/ivanam/downloads/muscle3.6_src/muscle";
$profile  = "/home/ivanam/perlscr/rec_best_hit_pack/profile_almt.pl";

$filename = "unresolved_mutual_hits";
open (UMH, ">$filename" ) 
    || die "Cno $filename: $!.\n";

($qid, $sid, $pid, $almt_lgth, 
 $mismatches, $gap_openings, $q_start, $q_end, 
 $s_start, $s_end, $e_value, $bit_score) = ();

$qry_seq = `grep -v \'>\' $qry_seqfile`;
$qry_seq =~ s/[\n\s]//g;
print "$qry_seq\n";
$qry_seq_length = length $qry_seq;
#################################################
# a piece of "parametrization" here
$shortest_acceptable_almt_length = $acceptable_fraction*$qry_seq_length;

print "length: $qry_seq_length  shortest acceptable: $shortest_acceptable_almt_length \n";


#################################################
# read in the available species groups
$filename = "$dbdir/groups";
undef $/;
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";
@groups = split "\n", <IF>;
close IF;
$/ = "\n";


#################################################
# make sure we have no blank spaces in the names
grep ( s/\s//g, @groups);
foreach $group ( @groups ) {
    @{$species{$group}} = split "\n", `cat $dbdir/$group/species`;
}

#################################################
# make directory for each group of species
foreach $group ( @groups ) {
   ( -e $group) || `mkdir $group`;
}

###########################################################
# is the query species present (or recognized)?
$spec_found = 0;
foreach $group ( @groups ) {
    ( -e $group) || `mkdir $group`;
    if ( grep ( /$qry_spc/, @{$species{$group}} ) ) {
	$spec_found = 1;
	$qry_group  = $group;
	last;
    }
}

$spec_found || die "$qry_spc not found\n";

###########################################################
# sanity check: can query be found cleanly in its own species genome?
if ( ! -e "$qry_group/$qry_spc.blastp") {
    $cmd  = "$blast -d $dbdir/$qry_group/$qry_spc -i $qry_seqfile ";
    $cmd .= " -o $qry_spc.blastp -m 9 -e 1.e-3 ";
    (system $cmd) && die "Error running $cmd\n";
    `mv  $qry_spc.blastp $qry_group`;
}

$qry_found = 0;
$gis = "";
@blastlines = split "\n", `cat $qry_group/$qry_spc.blastp`;
$best_hit_length = -1;
foreach $line (@blastlines) {
    next if ($line =~ /^#/);
    ($qid, $sid, $pid, $almt_lgth, 
     $mismatches, $gap_openings, $q_start, $q_end, 
     $s_start, $s_end, $e_value, $bit_score) = split " ", $line;
    ( $best_hit_length < 0 ) && ($best_hit_length = $almt_lgth );
    if ( ($pid > 99.5 || $e_value == 0) && $almt_lgth >= $best_hit_length ) {
	$qry_found ++;
		
	@aux = split '\|', $sid;
	$gis .= $aux[1]."\n";
    }
}

# retrieve all hits
$filename = "$qry_group/$qry_spc.gi";
open (OF, ">$filename") || die "Cno $filename:  $!\n";
print OF $gis;
close OF;
$cmd = "$fastacmd  -d $dbdir/$qry_group/$qry_spc -i $filename > tmp"; 
(system $cmd) &&  die "Error running $cmd.\n";
`$gi_names < tmp > $qry_group/$qry_spc.seq`;
`rm tmp`;

($qry_found) || die "Query not found in its own species ... ?\n";

($qry_found < 2) || 
    die "Several homologues found in own species.".
    " (See $qry_group/$qry_spc.blastp and $qry_group/$qry_spc.seq).\n";

($qry_gi) = split "\n", $gis;




###########################################################
# blast query against each specie in each group
foreach $group ( @groups ) {
    foreach $specie (  @{$species{$group}}  ) {
	next if ( -e "$group/$specie.blastp");
	$cmd  = "$blast -d $dbdir/$group/$specie -i $qry_group/$qry_spc.seq ";
	$cmd .= " -o $specie.blastp -m 9 -e 1.e-3 ";
	(system $cmd) && die "Error running $cmd\n";
	`mv  $specie.blastp $group`;
    }
}



###########################################################
# for each specie: find the best hit sequence
foreach $group ( @groups ) {
    foreach $specie (  @{$species{$group}}  ) {
	next if ( $specie eq $qry_spc );
	next if ( -e "$group/$specie.seq" || -e " $group/$specie.no_hit" );

	@blastlines = split "\n", `cat $group/$specie.blastp`;
	$gis = "";
	foreach $line (@blastlines) {
	    next if ($line =~ /^#/);
	    ($qid, $sid, $pid, $almt_lgth, 
	    $mismatches, $gap_openings, $q_start, $q_end, 
	    $s_start, $s_end, $e_value, $bit_score) = split " ", $line;
	    next if ( $almt_lgth < $shortest_acceptable_almt_length);

	    @aux = split '\|', $sid;
	    $gis .= $aux[1]."\n";
	    last;
	}
	if ( ! $gis ) {
	    `touch $group/$specie.no_hit`;
	    next;
	}
	# retrieve the sequence
	$filename = "$group/$specie.gi";
	open (OF, ">$filename") || die "Cno $filename:  $!\n";
	print OF $gis;
	close OF;
	$cmd = "$fastacmd -d $dbdir/$group/$specie -i $filename > tmp"; 
	(system $cmd) &&  die "Error running $cmd.\n";
	`$gi_names < tmp > $group/$specie.seq`;
	`rm tmp`;
	
	
    }
}

###########################################################
# for each specie: blast the best hit against the query specie database:
foreach $group ( @groups ) {
    foreach $specie (  @{$species{$group}}  ) {
	next if ( $specie eq $qry_spc );
	next if ( -e "$group/$specie.no_hit" );
	next if ( -e "$group/$specie\_vs_$qry_spc.blastp" );

	$seqfile = "$group/$specie.seq";
	$cmd  = "$blast -d $dbdir/$qry_group/$qry_spc -i $seqfile ";
	$cmd .= " -o $specie\_vs_$qry_spc.blastp -m 9 -e 1.e-3 ";
	(system $cmd) && die "Error running $cmd\n";
	`mv $specie\_vs_$qry_spc.blastp  $group`;
 	
    }
}


###########################################################
# for each specie: what is the best mutual hit in the qry genome?
foreach $group ( @groups ) {
    $group_fasta = "$group/$group.fasta";
    ( -e $group_fasta ) && `rm $group_fasta ; touch $group_fasta`;

    foreach $specie (  @{$species{$group}}  ) {
	if ( $specie eq $qry_spc ){
	    `cat $qry_seqfile >> $group_fasta`;
	    next;
	}
	next if ( -e "$group/$specie.no_hit" );

	@blastlines = split "\n", `cat $group/$specie\_vs_$qry_spc.blastp`;
	$gis = "";
	$best_gi = 0;
	foreach $line (@blastlines) {
	    next if ($line =~ /^#/);
	    ($qid, $sid, $pid, $almt_lgth, 
	    $mismatches, $gap_openings, $q_start, $q_end, 
	    $s_start, $s_end, $e_value, $bit_score) = split " ", $line;

	    @aux = split '\|', $sid;
	    $gis .= $aux[1]."\n";
	    $best_gi || (  $best_gi=$aux[1] );
	}
	if ( ! $gis) {
	    warn "No reciprocal hit for $specie (?).\n";
	    next;
	}

	# save the $gis
	$filename = "$group/$specie\_vs_$qry_spc.gi";
	open (OF, ">$filename") || die "Cno $filename:  $!\n";
	print OF $gis;
	close OF;

	# if it is the mutual best hit, collect the sequences
	if ( $best_gi == $qry_gi ) {
	    $seqfile = "$group/$specie.seq";
	    `cat $seqfile >> $group_fasta`;
	} else {
	    warn "query ($qry_gi) not best hit ($best_gi) (in $qry_spc for $specie ...)\n";
	    print UMH "query ($qry_gi) not best hit ($best_gi) in $qry_spc for $specie\n";
	}
    }
}

###########################################################
# align fasta files 
$afas = "";
foreach $group ( @groups ) {
    $group_fasta = "$group/$group.fasta";
    $group_afa   = "$group/$group.afa";
    next if ( ! -e $group_fasta ||  -z $group_fasta );
    if ( ! -e $group_afa ) {
	$cmd = "$muscle -in  $group_fasta -out $group_afa \n";
	(system $cmd) && die "Error running $cmd.\n";
    }
    $afas .= $group_afa."\n";
}
 
$filename = "all_afas";
open (OF, ">$filename") || die "Cno $filename:  $!\n";
print OF $afas;
close OF;
print $afas, "\n";


close UMH;

###########################################################
# align the alignments 
print `$profile $filename`;
