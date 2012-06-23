#!/usr/bin/perl -w

# can I get rid of seq longer than, say 30 or 26?

sub check_distance (@);
sub hits_per_nucleotide (@);
sub parse_number_of_reads (@);
sub output();
sub output_stats ();
sub process_regions();

$illumina_data = "filtered_EX2.fasta";
( -e $illumina_data) || die "$illumina_data not present.\n";

$genome_dir    = "/home/ivanam/projects/colabs/Vivek/mirna/genomes/genome_hs";
$script_dir    = "/home/ivanam/projects/colabs/Vivek/mirna/peedrim/scripts";
$known_mirna_coords = "/home/ivanam/projects/colabs/Vivek/mirna/known/hsa.genome_coordinates.mirbase";


#########################################################
# check the lengths of the queries;
# signal that they are too long by not storing them at all
open (IF, "<$illumina_data") || die "Cno $illumina_data:$!\n";
while ( <IF> ) {
   next if ( ! /\S/ );
   chomp;
   if ( />(.+)/ ) {
       $name = $1;
       $name =~ s/\s//g;
   } else {
       $seq = $_;
       $seq =~ s/\s//g;
       $len = length $seq;
       if ( $len < 30 ) {
	   $query_length{$name} = $len;
       }
   }
}

printf "done reading illumina\n";


#########################################################
# store the positions on the genome which are known
# to code for miRNA
open (IF, "<$known_mirna_coords") || die "Cno $known_mirna_coords:$!\n";

while ( <IF> ) {
    next if ( ! /\S/ );
    next if ( /^#/ );
    @aux = split;
    $strand = $aux[6];
    $chrnum = shift @aux;
    $id = pop @aux;
    $id =~ s/ID=\"//;
    $id =~ s/\"\;//;
    $id =~ s/miR/mir/;
    ($from, $to) = @aux[2..3];

    # for each chromosome, there will be an 
    # array of coordinates of known miRNA
    # not that "chrnum" may be a character (X, Y, or M)
    if ( ! defined $known_coordinates{$chrnum} ) {
	# initialize the array, otherwise cannot use push
	@{$known_coordinates{$chrnum}} = ();
    } 
    push  @{$known_coordinates{$chrnum}}, "$from $to";

    # enable retrieving the information in the other direction:
    # given coordinates "$from $to", give me back the 
    # name of the miRNAM ($id) and the appropriate strand (+ or -)
    $known_id    {"$from $to"} = $id;
    $known_strand{"$from $to"} = $strand;
}
close IF;


##############
# if you want, you can uncomment this region
# to see the info about the known miRNA
# 
# foreach $chrnum ( keys %known_coordinates ) {
#     print "\n************\n$chrnum\n";
#     foreach $coord (  @{$known_coordinates{$chrnum}} ) {
# 	print "$coord  $known_id{$coord}\n";
#     }
# }
# 
# exit;
#############


######################################################
#  see which chromosomes are avialable
# -- each one fasta entry (starting with ">")  
# should have its own directory, and be formatted
# for (mega)blasting
@chrom_dirs = split "\n", `ls $genome_dir`;


######################################################
# check if there are any megablast files present 
# otherwise I am in the wrong directory, or something
$found = 0;
foreach $chromosome (@chrom_dirs) {

    $mgbl_out        = "$chromosome.megablast.out";
    $mgbl_sorted_out = "megablast_sorted/$chromosome.megablast.sorted.out";

    $mgbl_reduced_plus  = "$chromosome.mgbl_reduced.plus";
    $mgbl_reduced_minus = "$chromosome.mgbl_reduced.minus";

    next if (! -e $mgbl_out  && !  -e  $mgbl_sorted_out 
	&& ! -e $mgbl_reduced_plus 	&& ! -e $mgbl_reduced_minus );

    print "results of blasting against $chromosome found\n";
    $found++;
    
}
$found || die "no blast output found\n";


#########################################################
# sort megablast output by the beginning position of the match
# this piece of code you hae in blast_piece.pl too
foreach $chromosome (@chrom_dirs) {

    $mgbl_out = "$chromosome.megablast.out";
    $mgbl_sorted_out = "megablast_sorted/$chromosome.megablast.sorted.out";
    next if (! -e $mgbl_out);

    if ( -e $mgbl_reduced_plus 	&&  -e $mgbl_reduced_minus ) {
	print "$mgbl_reduced_plus  &&  $mgbl_reduced_minus found.\n";
    }  if (  -e  $mgbl_sorted_out ) {
	print "$mgbl_sorted_out found\n";
    } else {
	print "sorting $mgbl_out to $mgbl_sorted_out file\n";
	$cmd = "sort -gk 10 $mgbl_out > $mgbl_sorted_out";
	(system $cmd) && die "Error running $cmd\n";
    }
}



#########################################################
# reduce  megablast output to the full length hits shorter
# than 30 nt, and divide it into two strands
foreach $chromosome (@chrom_dirs) {

    $mgbl_sorted_out = "megablast_sorted/$chromosome.megablast.sorted.out";
    next if (! -e $mgbl_sorted_out);

    $mgbl_reduced_plus  = "$chromosome.mgbl_reduced.plus";
    $mgbl_reduced_minus = "$chromosome.mgbl_reduced.minus";

    if (  -e  $mgbl_reduced_plus   &&  -e  $mgbl_reduced_minus ) {
	print "$mgbl_reduced_plus &&   $mgbl_reduced_minus found\n";
	next;
    } 

    print "reducing $mgbl_sorted_out file\n";

    open (PLUS, ">$mgbl_reduced_plus")  || die "Cno $mgbl_reduced_plus: $!.\n";
    open (MINUS, ">$mgbl_reduced_minus") || die "Cno $mgbl_reduced_minus: $!.\n";
    
    open (SORTED, "<$mgbl_sorted_out") || die "Cno $mgbl_sorted_out: $!.\n";
    
    $ctr = 0;
    while ( <SORTED> ) {
	next if ( ! /\S/ );
	next if (  /^#/ );
	$ctr ++;
	( ! ($ctr % 1000000) ) && print "processed $ctr lines\n";
	($qry, $target, $pid, $length, $mismatches, $gaps,
	 $qfrom,  $qto, $tfrom, $tto, $evalue, $bitscore) = split " ";

	next if (  $length >= 30); # this is too long
	next if (  $qfrom  != 1); # this is not a full length match

	next if (  ! defined $query_length{$qry}); # query too long
	next if (   $length !=  $query_length{$qry}  ); # not a full length match
	
	if ( $bitscore eq "c" ) {
	    print MINUS;
	} else {
	    print PLUS;
	}
    }


    close SORTED;

    close PLUS;
    close MINUS;


}


#########################################################
# find hits in the regions of known miRNA hairpins, and extract
# them in the new file, while keeping the
# megablast format - the reason I am doing this
# is because this is still a rether lengthy step
# which actually needs to be done only once
# -- check out one of *known_miRNA.report files
# to see the format
foreach $chromosome (@chrom_dirs) {

    $report_file = "$chromosome.known_miRNA.report";
    if ( -e $report_file ) {
	# if the report is already present, move on
	print " $report_file found\n";
	next;
    }

    $mgbl_reduced_plus  = "$chromosome.mgbl_reduced.plus";
    $mgbl_reduced_minus = "$chromosome.mgbl_reduced.minus";

    next if (  ! -e  $mgbl_reduced_plus   && ! -e  $mgbl_reduced_minus );

    # get rid of "chr" from the chromosome name
    $chrnum = $chromosome;
    $chrnum =~ s/chr//;
    # if there are no know miRNAs for this chromosome
    # such is the case for chr*_rand pieces ( which are not exactly
    # chromosomes, but oh well) in that case also move on
    next if ( ! defined $known_coordinates{$chrnum} );


    # and then move on if you are not done blasting
    # this particular chromosome


    printf "$chromosome $chrnum \n"; 

    %hits = ();

    foreach $mbl_file (  $mgbl_reduced_plus, $mgbl_reduced_minus) {

	printf "looking for hits on $chromosome, using $mbl_file\n";

	if (  $mbl_file =~ "plus" ) {
	    $strand = "+";
	} else {
	    $strand = "-";
	}

	open ( IF, "<$mbl_file" ) || 
	    die "Error opening $mbl_file\n";

	($qry, $target, $pid, $length, $mismatches, $gaps,
	 $qfrom,  $qto, $tfrom, $tto, $evalue, $bitscore)= ();

	
	$coord_ctr = -1;
	$current_to = 0;

	while ( <IF> ) {

	    next if ( ! /\S/ );
	    next if (  /^#/ );
	    
	    ($qry, $target, $pid, $length, $mismatches, $gaps,
	     $qfrom,  $qto, $tfrom, $tto, $evalue, $bitscore) = split " ";


	    # if the current miRNA coordinate ($current_to, $current_from)   
	    # is smaller than the hit
	    # from megablast that I am looking at ($tfrom, $tto), then advance to the next
	    # miRNA, and so on, until either we find a hit
	    # or the current coordinate is larger than the megablast hit
	    # (in which case advance to the next megablast hit)
	    # or we hit the end of the list of known miRNA  
	    # ( ensured by $coord_ctr < $#{$known_coordinates{$chrnum}}  condition)
	    while (  $tfrom> $current_to  &&  $coord_ctr < $#{$known_coordinates{$chrnum}}) {
		$coord_ctr ++; 
		$coord = $known_coordinates{$chrnum}[$coord_ctr];
		next if ( $known_strand{$coord} ne $strand );
		($current_from, $current_to) = split " ", $coord  ;
		print " $known_id{$coord}:  $strand  $current_from -- $current_to \n"; 
	    };

	    # the end of known miRNA list
	    last if (  $coord_ctr == $#{$known_coordinates{$chrnum}});
	
	    # the list of known miRNA is ahead of
	    # the list of the megablast hits, so advance the latter
	    next if (  $tto < $current_from );


	    # store the hits and output them all at
	    # once - not ncessary to do it this way
	    # (not sure why I am doing it, but its OK)
	    if ( ! defined $hits{$coord} ) {
		@{$hits{$coord}} = ();
	    }
	    push @{$hits{$coord}}, $_; # note: $_ contains the line from the input <IF>
	}
	close IF;
    }
    
    # output hits for this chromosome
    output();

}


#########################################################
#########################################################
#########################################################
#
#
# the central piece of the script:
# process the hits -- once you understand this piece, you can
# delete it and write  your own -- then I think you'll
# have the confidence that you are really on top of the things

$total_miRNA_targets  = 0;  # the total number of miRNA hairpin positions  (hairpins for short)
                            # in the chromosomes that we have in the work directory

$has_a_hit = 0;             # how many hairpins  have hits in at least one region?
                            # (we are expecting up to 3, for miRNA, miRNA* and loop)

$has_2_hits = 0;            # how many hairpins have two distinct regions which have hits
                            # (we expect these to be miRNA and miRNA*, 
                            # but are not sure untill we chech for complementarity)

$has_3_hits = 0;            # how many hairpins have 3 regions (we think it might be the loop)

foreach $chromosome (@chrom_dirs) {

    $report_file = "$chromosome.known_miRNA.report";
    # remeber that the list of chromosomes
    # contains names like chr1_radnom,
    # for which there will be no report, and no known coordinates
    next if ( ! -e $report_file );
    $chrnum = $chromosome;
    $chrnum =~ s/chr//;
    next if ( ! defined $known_coordinates{$chrnum} );

    #count the total number of hairpins we could hit in principle
    $total_miRNA_targets += $#{$known_coordinates{$chrnum}} + 1;

    $mgbl_sorted_out = "megablast_sorted/$chromosome.megablast.sorted.out";
    next if ( ! -e  $mgbl_sorted_out );
    # the report file kindly informs us there were no hits
    # the purpose of having this file then is to know
    # that we did perform the search, but have found no hits
    next if ( `head -n 1  $report_file` =~ "no hits");

    printf "\n*********************************\n";
    printf "processing  hits on $chromosome\n";

    # read in the whole chromosome sequence -- we'll use it to
    # extract the pieces that had a hit, and check for
    # complementarity between the putative miRNA and miRNA* pieces
    $chromosome_sequence = `grep -v \'>\' $genome_dir/$chromosome/$chromosome.fa`;
    chomp $chromosome_sequence;
    $chromosome_sequence =~ s/\n//g;


    open ( IF, "<$report_file" ) || 
	die "Error opening $report_file\n";

    $total_no_hits = 0;
    $fully_within  = 0;
    $partial  = 0;
    ($prev_to, $prev_from) = (0, 0);

    # for each miRNA hairpin keep track
    # of non-overlapping regions ( @region array)
    # how many hits each region gets
    # what is the avg legnth of the hits which 
    # land in that region, and what is the 
    # standard deviation in that length
    # $region_ctr will count home many
    # regions there are (actually, it will store the number of regions
    # minus 1, but its a technicality) 
    @region      = ();
    @region_hits = ();
    @region_avg_length = ();
    @region_length_stdev = ();
    $region_ctr = -1;
    while ( <IF> ) {
	next if ( !/\S/ );

	chomp;

	if ( /^hsa/ ) {
	    # whenever we get to the lne with a 
	    # new miRNA name, store what we found
	    # for hte previous one
	    if ($total_no_hits){ # except the first time around
		                 # there is no previous

		process_regions(); # here happens the statistics - averaging, summing, what not
		output_stats ();
	    }
	    # reintialize everything for the new hairpin
	    ($id, $coord_from, $coord_to) = split;
	    $total_no_hits = 0;
	    $fully_within  = 0;
	    $partial  = 0;
	    ($prev_to, $prev_from) = (0, 0);
	    @region = ();
	    @region_hits = ();
	    @region_avg_length = ();
	    @region_length_stdev = ();
	    @region_avg_mid = ();
	    @region_mid_stdev = ();
	    $region_ctr = -1;

	} else {
	    # what is being split here is $_, that is, the new line of input
	    ($qry, $target, $pid, $length, $mismatches, $gaps,
	     $qfrom,  $qto, $tfrom, $tto, $evalue, $bitscore) = split " ";
	    # parse the name of the query -- it stores the absolute number of hits
	    $qry =~ /_x(\d+)/;
	    if ( defined $1 ) {
		$count = $1;
	    } else {
		$count = 1;
	    }
	    $total_no_hits += $count;

	    # hom many hits are  fully within the miRNA hairpin address ($coord_from,  $coord_to)?
	    if ( $coord_from <= $tfrom && $tto <= $coord_to ) {
		$fully_within += $count;
	    } else {
		$partial  += $count;
	    }

	    # which hits are overlappinng? store them as the same "region"
	    # the @region is the array of arrays
	    # its first index, $region_ctr, which we expect to be 0,1 or 2
	    # goes over the regions in the hairpin (putative miRNA, miRNA* and loop regions)
	    # while the second ones goes through all entries from the illumina input
	    # which fall within this region
	    $overlap = check_distance ( $prev_from, $prev_to, $tfrom, $tto);
	    if ( $overlap eq "non" ) { # if the region does not overlap with the previous one
                                       # start a new region
		$region_ctr ++;
		@{$region[$region_ctr]}  = ("$tfrom $tto $count"); 

	    } else { # if the region overlap with the previous one, sttore them together
		push @{$region[$region_ctr]}, "$tfrom $tto $count"; 
	    }
	    ($prev_to, $prev_from) = ( $tto, $tfrom);
  	}
    }
    close IF;
    
    process_regions();
    output_stats ();



}
#########################################################
# overall stats:

# how many times do we see the loop
# how many times do we see the overhang
# what is the ratio of counts of  mir to mir*
# how distant are they
# how complementary
print "*********************************\n";
print "*********************************\n";
print "*********************************\n";
print "overall stats: \n\n";
print "Nn chromosomes that were considered here, there are $total_miRNA_targets known miRNAs\n";
print "$has_a_hit of those have a piece represented in the Illumina sample,\n";
print "and $has_2_hits have hits in two regions, possibly representing miRNA and miRNA*.\n";
print "Only $has_3_hits case(s) have three hits, possibly indicating finding of the loop.\n";


exit;

#########################################################
#########################################################
#########################################################

sub process_regions() {

   my $ctr;
   my $hit;
   my ($from, $to, $count);
   my ($length, $length_sq);
   my ($avg, $avg_sq);
   my $tot = 0;

   # How many regions do we have here?
   # Add it to the overall statistics on how many  regions
   # do we see in miRNA hairpins
   $has_a_hit ++;
   if ( $region_ctr == 1 ) {
       $has_2_hits ++;
   } elsif  ( $region_ctr == 2 ){
       $has_3_hits ++;
   }

   # for each region find the avergae length of the hits
   # (and the standar deviation to go with it)
   for $ctr ( 0 .. $region_ctr) {

       ($avg, $avg_sq, $avg_mid, $avg_mid_sq) = (0,0,0,0);
       $tot = 0;

       ($temp_origin) = ($from, $to, $count) = split " ", $region[$ctr][0];

       foreach $hit ( @{$region[$ctr]} ) {
	   ($from, $to, $count) = split " ", $hit;
	   
	   $from -= $temp_origin;
	   $to   -= $temp_origin;

	   $length    = $to - $from + 1;
	   $length_sq = $length*$length;
	   $avg      += $length*$count;
	   $avg_sq   += $length_sq*$count;

           $tot += $count;

           $mid_seq     = ($to + $from)/2;
           $mid_sq      = $mid_seq*$mid_seq;
	   $avg_mid    += $mid_seq*$count;
	   $avg_mid_sq += $mid_sq *$count;
       }
       $avg    /= $tot;
       $avg_sq /= $tot;
       $avg_mid    /= $tot;
       $avg_mid_sq /= $tot;

       $region_hits[$ctr] = $tot;
       $region_avg_length[$ctr]   = sprintf "%4.1f", $avg;
       $region_length_stdev[$ctr] = sprintf "%4.1f", sqrt($avg_sq - $avg*$avg);
       $region_avg_mid[$ctr]      = sprintf "%4.1f", ($avg_mid+$temp_origin);
       $region_mid_stdev[$ctr]    = sprintf "%4.1f", sqrt($avg_mid_sq - $avg_mid*$avg_mid);
   }

   # if the region has either one hit, that's it - return
   $match = "";
   $alignment = "";
   return if ( $region_ctr != 1);

   # if the region has two hits, see if they are complementary;
   # hits_per_nucleotide function basically gets rid of positions
   # wich only some weird hits poses - in other words
   # it picks the postions that majority of hits agree on
   ($from, $to) = hits_per_nucleotide (@{$region[0]});
   $seq5 = uc substr ($chromosome_sequence, $from-1, $to-$from+1);

   ($from, $to) = hits_per_nucleotide (@{$region[1]});
   $seq3 = uc substr ($chromosome_sequence, $from-1, $to-$from+1);

   $seq3_revc = revcom($seq3);


   # "needle"  is a piece of C code which does the aligment
   # it is C, because I had it lying around
   $cmd = "$script_dir/needle $seq5 $seq3_revc >& needle.tmp";

   if ( ! system $cmd  ) { # there seems to be abug for single nt type seqs - move on
	
       # process the output of needle ( check out needle.tmp file)
       # into the alignment length info, and the liagnment itself
       $ret = `tail -n1 needle.tmp`;
       chomp $ret;

       ($aligned_nt, $matching_nt) = split " ", $ret;
       $match =  "$aligned_nt  $matching_nt";

       $seq5 = "";
       $seq3 = "";
       @almt_lines = split "\n", `cat needle.tmp`;
       foreach (@almt_lines) {
	   last if ( /\d/ );
	   chomp;
	   ($a, $b) = split " ";
	   $seq5 .= $a;
	   $seq3 .= $b;
       }
       $alignment = "\t $seq5\n\t $seq3"; 

   }
  
   # the alignment in the regions extended by, say 10:
   ($from, $to) = hits_per_nucleotide (@{$region[0]});
   $from -= 10;
   $seq5 = uc substr ($chromosome_sequence, $from-1, $to-$from+1);

   ($from, $to) = hits_per_nucleotide (@{$region[1]});
   $to +=  10;
   $seq3 = uc substr ($chromosome_sequence, $from-1, $to-$from+1);
   $seq3_revc = revcom($seq3);
   $cmd = "$script_dir/needle $seq5 $seq3_revc >& needle.tmp";
   if ( ! system $cmd  ) {
			    
       $ret = `tail -n1 needle.tmp`;
       chomp $ret;

       ($aligned_nt, $matching_nt) = split " ", $ret;
       $match .=  "\n\t $aligned_nt  $matching_nt";

   }
  
}


#########################################################
#########################################################
#########################################################

sub output_stats() {
    my $ctr;
    print "\n";
    print "$id  $coord_from  $coord_to\n";
    print "strand: ", $known_strand{"$coord_from $coord_to"}, " \n";
    print "total hits:  $total_no_hits\n";
    print "partially overlapping hits: $partial\n";
    print "hits fully within: $fully_within\n";
    print "mutually non-overlapping clusters of hits: ", $region_ctr+1, "\n";
    for $ctr ( 0 .. $region_ctr) {
	print "\t $region_hits[$ctr]  $region[$ctr][0]  ".
	    "length: $region_avg_length[$ctr] p/m $region_length_stdev[$ctr] \n";	
	print  "\t average mid position = $region_avg_mid[$ctr] p/m $region_mid_stdev[$ctr]\n";	
	foreach $hit ( @{$region[$ctr]} ) {
	    print "\t\t $hit\n";
	}
    }
    $match && print "\t $match\n"; # if no $match is returned, then don't try to  print it
    $alignment && print "$alignment\n";
}

#########################################################
#########################################################
#########################################################

sub output() {

    open (OF, ">$report_file") || die "Cno $report_file: $!\n";
    
    if ( ! keys %hits ) {
	print OF "no hits found on $chromosome\n";

    } else {

	foreach $coord ( keys %hits ) {
	    print OF "\n";
	    print OF "$known_id{$coord}:  $coord \n";
	    print OF  @{$hits{$coord}};
	}
    }
    close OF;

}



#########################################################
#########################################################
#########################################################
sub check_distance (@) {

    my ($prev_tfrom, $prev_tto, $tfrom, $tto) =  @_;

    if ($prev_tfrom == 0 ) {
	return "non";

    }  elsif ($prev_tto - $tfrom  > 0  )  {
	return "overlapping";

    } else {
	return "non";
	
    }
   
       

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

    ($start, $to) = split " ", $candidate_regions[0];
    ($from, $end) = split " ", $candidate_regions[$#candidate_regions];


   #return ( $start, $end);
 
   for ($i = 0; $i < $end-$start; $i++) {
	$count[$i]  = 0;
    }

    foreach (@candidate_regions ) {
	($from, $to)  = split " ";
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

