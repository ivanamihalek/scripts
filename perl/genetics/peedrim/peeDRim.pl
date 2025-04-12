#!/usr/bin/perl -w

sub check_distance (@);
sub hits_per_nucleotide (@);
sub parse_number_of_reads (@);
sub output();

$genome_dir    = "/home/ivanam/projects/colabs/Vivek/mirna/genomes/genome_hs";
$current_input = "raw_EX3.fasta";

$script_dir = "/home/ivanam/projects/colabs/Vivek/mirna/peedrim/scripts";
if ( ! -e $current_input ) {
    die "$current_input, the initial input file, not found\n";
} else {
    ($no_entries) = split " ", `grep \'>\' $current_input | wc -l`;
    print "$current_input found with $no_entries sequences\n";
}


########################################################
# filter out low complexity regions

$new_fasta = "filtered_EX3.fasta";
if ( ! -e $new_fasta ) {
    print "filtering out low complexity regions, new file will be $new_fasta \n";
    $cmd = "$script_dir/filter_low_cplx.pl $current_input > $new_fasta";
    (system $cmd) && die "Error running $cmd\n";
} else {
    print "$new_fasta found\n";
}

$current_input = $new_fasta;
($no_entries) = split " ", `grep \'>\' $current_input | wc -l`;
$no_lines = 2*$no_entries;

print "$current_input contains $no_entries sequences\n";


#  see which chromosomes are avialable
# -- each one should have its directory, and be formatted
# for (mega)blasting
@chrom_dirs = split "\n", `ls $genome_dir`;

#
#########################################################
# blast against the genome
# megablast of ~ 220,000 entries against C.elegans genome 
# with -M 50,000 option, -p 70, takes about 230s user time
# with -M 10,000 option, -p 70, takes about 270s user time
# by input splitting as below: 132 s
#
#
# when mapping to the genome, will take only 100% identical
# matches with the forward strand



#
#
#
#
foreach $chromosome (@chrom_dirs) {

    $mgbl_out = "$chromosome.megablast.out";
    $mgbl_sorted_out = "$chromosome.megablast.sorted.out";

    if ( -e $mgbl_out  ||  -e  $mgbl_sorted_out ) {
	print "results of blasting against $chromosome found\n";
    }  else {

	print "blasting $current_input against $chromosome  \n";

	$start_time = time;
	$big_fasta = $current_input;

	`touch $mgbl_out`;

	$processed = $chunk = 0;
	while ( $processed < $no_lines ) {

	    if ( $no_lines - $processed < 1000 ) {
		$chunk = $no_lines - $processed;
	    } else {
		$chunk = 1000;
	    }

	    $begin = $processed + $chunk;
	    print "$no_lines  $begin  $chunk \n";
 
	    `head -n $begin $big_fasta | tail -n  $chunk > tmp.fasta`;

	    $cmd = "nice megablast -d $genome_dir/$chromosome/$chromosome.fa -i tmp.fasta ".
		" -F F -W 12 -D 3 -p 100   | awk \'\$11 < 1.e-2 \' |".
		" awk \'{if (\$9 < \$10) {print} else ".
		" {tmp=\$9; \$9=\$10; \$10=tmp; \$12 = \"c\"; print}}\' ".
		" >> $mgbl_out";
	    system $cmd;

	    $processed += $chunk;

 	}

	`rm  tmp.fasta`;
	print "\t done with $chromosome(", time-$start_time, "s)\n";  

    }
}


#########################################################
# sort megablast output by the beginning position of the match

foreach $chromosome (@chrom_dirs) {

    $mgbl_out = "$chromosome.megablast.out";
    $mgbl_sorted_out = "$chromosome.megablast.sorted.out";

    if (  -e  $mgbl_sorted_out ) {
	print "$mgbl_sorted_out found\n";
    } else {
	print "sorting $mgbl_out to $mgbl_sorted_out file\n";
	$cmd = "sort -gk 10 $mgbl_out > $mgbl_sorted_out";
	(system $cmd) && die "Error running $cmd\n";
    }
}

exit;

#########################################################
# find positions on the genome which have two
# almost contiguous hits - these will be our
# candidates for miRNA and miRNA*

$cnd_file = "candidates.fasta";

if (  -e $cnd_file && ! -z $cnd_file ) {
    printf "$cnd_file found\n";

} else {

    open (OF, ">$cnd_file") || die "Cno $cnd_file: $!\n";


    print "\n";
    $prev_qry = "";
    foreach $chromosome (@chrom_dirs) {

	$chromosome_sequence = `grep -v \'>\' $genome_dir/$chromosome/$chromosome.fa`;
	chomp $chromosome_sequence;
	$chromosome_sequence =~ s/\n//g;
   
	$mgbl_sorted_out = "$chromosome.megablast.sorted.out";
	printf "looking for contiguous hits on $chromosome, using $mgbl_sorted_out\n";

	open ( IF, "<$mgbl_sorted_out" ) || 
	    die "Error opening $mgbl_sorted_out\n";

	($qry, $target, $pid, $length, $mismatches, $gaps,
	 $qfrom,  $qto, $tfrom, $tto, $evalue, $bitscore)= ();
	
	($prev_tfrom, $prev_tto, $tfrom, $tto) = (0,0,0,0);

	@five_prime_arm_candidates = ();
	@three_prime_arm_candidates = ();
    
	$total_candidate_hairpins = 0;
	while ( <IF> ) {

	    ($qry, $target, $pid, $length, $mismatches, $gaps,
	     $qfrom,  $qto, $tfrom, $tto, $evalue, $bitscore) = split " ";

	    $distance  = check_distance($prev_tfrom, $prev_tto, $tfrom, $tto);
	

	    if ( $distance eq "distant" ) {
	    
		if ( @three_prime_arm_candidates ) {
		

		    # left arm hits:"
		    ($start5arm, $end5arm) = hits_per_nucleotide @five_prime_arm_candidates;

		    # right arm hits:"
		    ($start3arm, $end3arm) = hits_per_nucleotide @three_prime_arm_candidates;


		    $number_of_5prime_candidates = parse_number_of_reads @five_prime_arm_candidates;
		    $number_of_3prime_candidates = parse_number_of_reads @three_prime_arm_candidates;

		    $length5 = $end5arm - $start5arm + 1;
		    $length3 = $end3arm - $start3arm + 1;
		    $length_loop = $start3arm - $end5arm + 1;

		    if (  ( $number_of_5prime_candidates > 5 &&  $number_of_3prime_candidates > 5) &&
			$end3arm - $start5arm <  150  && $length5 < 26 && $length3 < 26) {

			# align canidate mature && "star"
			$overhang_length = 0;
			$matching_nt = 0;

			$seq5 = uc substr ($chromosome_sequence, $start5arm-1, $end5arm-$start5arm+1);
			$seq3 = uc substr ($chromosome_sequence, $start3arm-1, $end3arm-$start3arm+1);
			$seq3_revc = revcom($seq3);
			$cmd = "$script_dir/needle $seq5 $seq3_revc >& needle.tmp";
			if ( ! system $cmd  ) { # there seems to be abug for single nt type seqs - move on
			    
			    $ret = `tail -n1 needle.tmp`;
			    chomp $ret;

			    ($aligned_nt, $matching_nt) = split " ", $ret;

			    @lines = split "\n", `head -n6 needle.tmp`;
			    $overhang_length = 0;
			    for $line_ctr ( 0 .. 5) {
				($nuc1) = split " ", $lines[$line_ctr];
				last if ( $nuc1 ne "." );
				$overhang_length ++;
			    }
			}
			
			if ( $overhang_length>=1 && $overhang_length<=3 && $matching_nt > 14 ) {
			
			    # align "pre" hairpin
			    $start5pri = $start5arm - 20; # for pri RNA
			    $end5pri   = $end5arm;

			    $end3pri   = $end3arm +20; # for pri RNA
			    $start3pri = $start3arm;
			    $seq5 = uc substr ($chromosome_sequence, $start5pri-1, $end5pri-$start5pri+1);
			    $seq3 = uc substr ($chromosome_sequence, $start3pri-1, $end3pri-$start3pri+1);
			    $seq3_revc = revcom($seq3);
			    $cmd = "$script_dir/needle $seq5 $seq3_revc >& needle.tmp";
			    if ( ! system $cmd  ) { # there seems to be abug for single nt type seqs - move on
			    
				$ret = `tail -n1 needle.tmp`;
				chomp $ret;

				($aligned_nt, $matching_nt) = split " ", $ret;


				if ( $aligned_nt >= 25 && $matching_nt >= 20 ) {

				    $seq  = uc substr ($chromosome_sequence, $start5pri-1, $end3pri-$start5pri+1);

				    output();
				    $total_candidate_hairpins ++;
				}
			    }
			}
			#( $start3arm  - $end5arm < 2 ) &&
			#	die "loop region (?) \n";
		    }
		}

		@five_prime_arm_candidates = ("$qry $tfrom $tto");
		@three_prime_arm_candidates = ();

   
	    } elsif ( $distance eq "overlapping" ) {
		#print "XXXXXXX $prev_qry $prev_tfrom, $prev_tto overlaps with $qry  $tfrom, $tto  \n";
		if (  @three_prime_arm_candidates ) { # we already moved to 3' arm
		    push  @three_prime_arm_candidates, "$qry $tfrom $tto"; 
		} else {
		    push  @five_prime_arm_candidates, "$qry $tfrom $tto"; 
		}

	    } elsif ( $distance eq "contiguous" ) {
	    
		if ( @three_prime_arm_candidates ) { # what's this?
		    $triple_contig ++;
		    # reboot
		    ($prev_tfrom, $prev_tto, $tfrom, $tto) = (0,0,0,0);

		    @five_prime_arm_candidates = ();
		    @three_prime_arm_candidates = ();
    
		} else {
		    push  @three_prime_arm_candidates, "$qry $tfrom $tto"; 
		}

	    }
	    if ( $distance ne "crap" ) {
		($prev_qry, $prev_tfrom, $prev_tto) = ($qry, $tfrom, $tto);
	    }
	}
	printf "\n total_candidate_hairpins  on chromosome $chromosome: $total_candidate_hairpins \n\n";
	print "**********************************************\n";
	print "**********************************************\n\n\n";
    }

    close OF;
}

( -e "needle.tmp") && `rm needle.tmp`;
printf "total triple contigs: $triple_contig\n\n";



#########################################################
#

# Check whether the precursors will hold structurally
# RNAfold has trouble recognizing know hairpins ...
# print "\nchecking precursors using RNAfold.\n";

# $rnf_out = "RNDfold.out";
# if ( ! -e "structures" ) {
#     $cmd = "RNAfold -noPS < $cnd_file > $rnf_out";
#     (system $cmd) && die "Error running $cmd\n";
# }



exit;

#########################################################
#########################################################
#########################################################

sub output() {
    print OF "> $chromosome\_$start5arm\_$end3arm\n$seq\n";

    print "********************************\n";
    print "candidate hairpin $chromosome\_$start5arm\_$end3arm \n";
				print "\t 5': $start5arm   $end5arm  $length5 \n";
    print "\t 3': $start3arm   $end3arm  $length3 \n";
    print "\t overhang length: $overhang_length\n";
    print "\t loop length: $length_loop\n";
    print "\t $number_of_5prime_candidates 5' arm candidates \n";
    print "\t $number_of_3prime_candidates 3' arm candidates \n";
    print "\t $seq5\n";
    print "\t $seq3_revc\n";
    print "\t $seq3\n";
    print "\t $seq\n";
    print `cat needle.tmp` ;
}



#########################################################
#########################################################
#########################################################
sub check_distance (@) {

    my ($prev_tfrom, $prev_tto, $tfrom, $tto) =  @_;

    if ($prev_tfrom == 0 ) {
	return "distant";

    }  elsif ($prev_tto - $tfrom + 1 >= 15  ) {
	return "overlapping";

     } elsif  ( $prev_tto < $tfrom - 30 ) {
	return "distant";

    } elsif  ( $prev_tto < $tfrom - 4 ) {
	return "contiguous";

    } else {
	return "crap";
	
    }
   
       

}
#########################################################
#########################################################
#########################################################
sub parse_number_of_reads (@) {

    my @candidate_regions = @_;
    my ($name, $from, $to);
    my $count = 0;;

    foreach (@candidate_regions ) {
	($name, $from, $to)  = split " ";
	$name =~ /_x(\d+)/;
	if ( defined $1 ) {
	    $count += $1;
	} else {
	    $count += 1;
	}
    }

    return $count;
   
}
#########################################################
#########################################################
#########################################################
sub hits_per_nucleotide (@) {

    my @candidate_regions = @_;
    my ($name, $from, $to);
    my ($start,$end);
    my $i;
    my @count;
    my ($avg, $stdev, $avg_sq);
    my $aux;
    my $legnth;
    my $max_count;

    ($name, $start, $to) = split " ", $candidate_regions[0];
    ($name, $from, $end) = split " ", $candidate_regions[$#candidate_regions];


   #return ( $start, $end);
 
   for ($i = 0; $i < $end-$start; $i++) {
	$count[$i]  = 0;
    }

    foreach (@candidate_regions ) {
	($name, $from, $to)  = split " ";
	for ($i = $from-$start; $i <= $to-$start; $i++) {
	    $count[$i] ++;
	}
    }

    ($avg, $stdev, $avg_sq) = (0, 0 );

    $length = $end-$start+1;
    $max_count = 0;
    for ($i = 0; $i < $length; $i++) {
	$aux = $count[$i];
	$avg    += $aux;
	$avg_sq += $aux*$aux;
	( $max_count < $count[$i]) && ($max_count = $count[$i]);
    }

    $avg /= $length;
    $avg_sq /= $length;
    $stdev = sqrt ($avg_sq - $avg*$avg);
    if ( $stdev == 0) {
	return ( $start, $end);
    } else {
	#print "\n\n\n$start  $end  $length\n";
	#foreach (@candidate_regions ) {
	#    print "$_ \n";
	#}
	#for ($i = 0; $i < $length; $i++) {
	#     print " $i $count[$i] \n";
	#}
	#print "$avg  $stdev\n\n";
	for ($i = 0; $i < $length; $i++) {
	     if ( $count[$i] > $avg - $stdev ) {
		 $start += $i;
		 last;
	     }
	}
	for ($i = $length - 1; $i >= 0; $i--) {
	     if ( $count[$i] > $avg - $stdev ) {
		 $end = $start + $i;
		 last;
	     }
	}
	
	$length = $end-$start+1;
	#print "NEW: $start  $end  $length\n";
    }
    return ( $start, $end);
    
}




sub rev{

    my($sequence)=@_;

    my $rev=reverse $sequence;   

    return $rev;
}

sub com{

    my($sequence)=@_;

    $sequence=~tr/acgtuACGTU/TGCAATGCAA/;   
 
    return $sequence;
}

sub revcom{

    my($sequence)=@_;

    my $revcom=rev(com($sequence));

    return $revcom;
}

