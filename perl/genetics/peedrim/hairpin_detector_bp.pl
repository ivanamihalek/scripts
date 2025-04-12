#!/usr/bin/perl -w

$MIN_BP_15        = 17;

$EXTENSION_LENGTH = 10;
$MIN_BP_EXTENDED  = 20;
$DIFF_BP_EXTENDED = 5;


sub check_distance (@);
sub hits_per_nucleotide (@);
sub parse_number_of_reads (@);
sub output();
sub output_stats ();
sub process_regions();

# number of nt to add onto region to check for dicer cleavage feasibility
# $nt_add must be 1 plus the no. of nt to add.
# min. value of $nt_add has to be 1 
$nt_add = 11;

# $nt_extend is the length of nucleotides to extend from the region to look
# for potential miRNA-miRNA* base pairing.
$nt_extend = 60;

$total_counter = 0;
$counter_5 = 0;
$counter_3 = 0;
$counter_died = 0;
$counter_negative = 0;


$illumina_data = "filtered_EX2.fasta";
( -e $illumina_data) || die "$illumina_data not present.\n";

$genome_dir = "/home/ivanam/projects/colabs/Vivek/mirna/genomes/genome_hs";
$script_dir = "/home/ivanam/projects/colabs/Vivek/mirna/peedrim/scripts";
#$known_mirna_coords = "/mnt/xtra/hs_dir/hsa.genome_coordinates.mirbase";



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

@chrom_dirs = split "\n", `ls $genome_dir`;




#########################################################################
#########################################################################
#########################################################################
# From the sorted output files, compare each entry with those 
# after it to identify entries that falls within the same region.
#
# Region is defined here as the specific length of nucleotides in the
# genome where the megablast output entries map onto. Each region may
# have more than one entry mapping onto it with partial / full overlap.
#
# if the current entry coordinate ($current_to, $current_from) is smaller
# than the next hit that I am looking at ($tfrom, $tto), then create a 
# new region until we hit the end of the sorted megablast output.
#

foreach $chromosome (@chrom_dirs) {

    $mgbl_reduced_plus  = "$chromosome.mgbl_reduced.plus";
    $mgbl_reduced_minus = "$chromosome.mgbl_reduced.minus";

    next if (  ! -e  $mgbl_reduced_plus   && ! -e  $mgbl_reduced_minus );

    print "\n*********************************\n";
    print "processing hits on $chromosome\n";

    foreach $mbl_file (  $mgbl_reduced_plus, $mgbl_reduced_minus) {

	printf "looking for hairpins on $chromosome, using $mbl_file\n";

	if (  $mbl_file =~ "plus" ) {
	    $strand = "+";
	} else {
	    $strand = "-";
	}

	open ( FILEHANDLER, "<$mbl_file" ) || 
	    die "Error opening $mbl_file\n";

	$region_counter = -1;
	$prev_from = 0;
	$prev_to = 0;

	$region_file = "$mbl_file"."_overlap_region";

        #assuming if $region_file exist, no need to re-write the file.
	if ( -e $region_file){
	    print  "$region_file found\n\n";
	    next;
	}

	open (REGION, ">$region_file")
	    or die "unable to open $region_file";

	while (<FILEHANDLER>) {
	    next if (/^#/);

            # parse the name of the entry to obtain the tag count detected by sequencing.

	    next if  (! /^EX/); # these are the only lines we are intersted in
	
	    ($qry, $target, $pid, $length, $mismatches, $gaps,
	     $qfrom,  $qto, $tfrom, $tto, $evalue, $bitscore) = split " ";
	
	    $qry =~ /_x(\d+)/;
	    if ( defined $1 ) {
		$count = $1;
	    } else {
		$count = 1;
	    }
	    $overlap = check_distance ( $prev_from, $prev_to, $tfrom, $tto);
	
	    if ($overlap eq "first") {
		$region_counter ++;
		@{$region[$region_counter]}  = ("$tfrom $tto $count $qry\t"); 
	    }elsif ( $overlap eq "non" ) { 

		# if the region does not overlap with the previous one
		# then save the old region and start a new region

		$region_counter ++;
		@{$region[$region_counter]}  = ("$tfrom $tto $count $qry\t"); 
	    
		$prev_counter = $region_counter - 1; 
		#print  "overlap_region = $prev_counter\n";
		#print join ("\n\t", @{$region[$prev_counter]}), "\n\n"; 
		print REGION "overlap_region = $prev_counter\n@{$region[$prev_counter]}\n\n"; 
		    
		# clear entries on previous array to free up memory space
		@{$region[$prev_counter]} = (); 

	    } else { 

		# if the region overlap with the previous one, sttore them together

		push @{$region[$region_counter]}, "$tfrom $tto $count $qry\t"; 
	    }
	    ($prev_to, $prev_from) = ( $tto, $tfrom);
	
	} # close while(<FILEHANDLER>) loop


	#print  "overlap_region = $region_counter\n@{$region[$region_counter]}\n\n";
	print REGION "overlap_region = $region_counter\n@{$region[$region_counter]}\n\n";
	@{$region[$region_counter]} = ();
	close REGION;
	close FILEHANDLER;  
    }  #close foreach $mbl_file ($mgbl_reduced_plus, $mgbl_reduced_minus) loop
 

    foreach $mbl_file ($mgbl_reduced_plus, $mgbl_reduced_minus) {
	print "calculating region data for $mbl_file.\n";

	open (REGION, "<$region_file") or die "unable to open $region_file";
        # for each region find the average length of the hits
        # (and the standard deviation to go with it)


	$region_counter = 0;
	$prev_counter_line = "";
	$output_file = "$mbl_file"."_region_data";

	if ( -e $output_file){
	    print "$output_file found\n\n";
	    next;
	}

	open (DATA, ">$output_file") or die "unable to open $output_file";
	while (<REGION>){
	    $line = $_;
    
	    if ($line=~ /overlap_region = (\d+)/ && $line ne $prev_counter_line){ 
		$region_counter =$1;
		next;
	    } elsif ($line =~ /\S/) { 

		chomp $line;

		@Blossom = split /\t/, $line;
		#use to  test:
		#foreach $flower (@Blossom ) {
		#    print "$flower\n";
		#}
		#exit;

		$value= calculate ();
		if ($value == 1){
		    output_calculate ();
		}

	    } else{
		#push @{$region[$region_counter]} , "$line"; 
		$prev_counter_line = "counter = $region_counter\n";
		next;
	    }
	    ( ! ($region_counter % 10000) ) && print "processed $region_counter regions\n";   

	} #close while (<REGION>) loop
	close REGION;
	close DATA;

    } #close foreach $mbl_file ($mgbl_reduced_plus, $mgbl_reduced_minus) loop
    last;


} # close foreach $chromosome (@chrom_dirs) loop



#########################################################
#########################################################
#########################################################
# read in the whole chromosome sequence -- we'll use it to
# extract the region and check for complementarity 
# between the region and it's surrounding nts, which would
# suggest hairpin formation.

foreach $chromosome (@chrom_dirs) { 

    print "reading in $chromosome sequence..\n"; 

    if ($chromosome ne "chr1") {print"done\n"; exit;}

    $chromosome_sequence = `grep -v \'>\' $genome_dir/$chromosome/$chromosome.fa`;
    chomp $chromosome_sequence;
    $chromosome_sequence =~ s/\n//g;
 
    $mgbl_reduced_plus  = "$chromosome.mgbl_reduced.plus_region_data";
    $mgbl_reduced_minus = "$chromosome.mgbl_reduced.minus_region_data";

    next if (  ! -e  $mgbl_reduced_plus   && ! -e  $mgbl_reduced_minus );

    foreach $mbl_file ($mgbl_reduced_plus, $mgbl_reduced_minus) {

	open (DATA, "<$mbl_file") or die "unable to open $mbl_file";

	while (<DATA>){
	    
	    if (/results for region = (\d+)/){
		$counter =$1; 
		$total_counter ++;
	    } 

	    # obtain the start and end coordinate of the region
	    if (/(\d+)...\d+ to \d+...(\d+)/) {
		$reg_from = $1;
		$reg_to = $2;
		$ref_from = $reg_from - $nt_extend ; 

                ###############################################################
                # Obtain reverse complement of the region for alignment.
                $reg_seq = uc substr ($chromosome_sequence, $reg_from-1, $reg_to-$reg_from+1);
		$revc_reg = revcom($reg_seq);

                # Obtain the stretch of 60nts from the region in both 5' and 3' directions
		$ref_seq5 = uc substr ($chromosome_sequence, $ref_from-1, $nt_extend);
		$cmd_5 = "$script_dir/needle $ref_seq5 $revc_reg > needle.tmp";

		$ref_seq3 = uc substr ($chromosome_sequence, $reg_to-1, $nt_extend);
		$cmd_3 = "$script_dir/needle $ref_seq3 $revc_reg > needle.tmp";

		($base_pair_5, $miRNA_star_5, $miRNA_5 ) = align($cmd_5);

		($base_pair_3, $miRNA_star_3, $miRNA_3 ) = align($cmd_3);


               #################################################################
               # Determine whether is the region located on the 5' or 3' end of a hairpin.
               # If the region is located on the 5' end of a hairpin, it will have 
               # significant base pairing with the 3' extension sequence.
               #
               # Even if we lengthen the region by 10 nt upstream, it will still maintain a high 
               # base-pairing with the 3' extension
               #
               # Conversely, if the region is located on the 3' end, 
	       # it will base pair with the 5' extension.

               # Here we determine base-pairing by complementary alignment of 
               # the same type of nucleotides using
               # Needleman-Wunsch algorithm. 
               # Thus, the proportion of correctly aligned nucleotides would be greater if it is
               # between the miRNA and miRNA*, compared to a random sequence.

		if ( $base_pair_5 <= $MIN_BP &&  $base_pair_3 <= $MIN_BP  ) {
		    
		    # If neither of the two extension can form a hairpin with the region, then it is not
                    # counted as a miRNA.
		    $counter_negative ++;

		} elsif ($base_pair_5 > $base_pair_3) {
		    $ret_string =  miRNA_3 ();
		    if ( $ret_string ) {
			print "\n\n****************************\n";
			print "for region $counter, miRNA is on the 3' end\n\n";
			print "alignment is \n\t$miRNA_5\n\t$miRNA_star_5\n\n";
			print "there are $base_pair_5 base pairs\n";
			print $ret_string;
		    }

		    

		} elsif ($base_pair_3 > $base_pair_5 ){
		    $ret_string = miRNA_5 ();
		    if ( $ret_string ) {
			print "\n\n****************************\n";
			print "for region $counter, miRNA is on the 5' end\n\n";
			print "alignment is \n\t$miRNA_3\n\t$miRNA_star_3\n\n";
			print "there are $base_pair_3 base pairs\n";
			print $ret_string;
		    }
		  
		} else {
		    print "\n\n#########################\n";
		    print "weirdness in region $counter:\n";

		    print "alignment is \n\t$miRNA_5\n\t$miRNA_star_5\n\n";
		    print "there are $base_pair_5 base pairs\n";
		    $ret_string =  miRNA_3 ();
		    print $ret_string;
		    
		    print "alignment is \n\t$miRNA_3\n\t$miRNA_star_3\n\n";
		    print "there are $base_pair_3 base pairs\n";
		    $ret_string =  miRNA_5();
		    print $ret_string;
		  
		    #die "\n";

		}

	    } #close if (/(\d+)...\d+ to \d+...(\d+)/) loop
	} # close while (<DATA>) loop
	print "results of analysing $mbl_file data\nthere is a total of $total_counter regions\n".
	    "there are $counter_5 5' hits\n"."there are $counter_3 3' hits\n".
	    "there are $counter_died dead hits\n"."there are $counter_negative negative hits\n";

    } # close foreach $mbl_file ($mgbl_reduced_plus, $mgbl_reduced_minus) loop


    last;

} # close foreach $chromosome (@chrom_dirs) loop

exit;
#########################################################
#########################################################
#########################################################
#
#sub routine
sub miRNA_3 {

   # Obtain the reverse complement of miRNA with an additional 10 nt to check for the ability of
   # hairpin to extend for Dicer cleavage.

    my$reg_seq5_10 = uc substr ($chromosome_sequence, $reg_from-1, $reg_to-$reg_from+$nt_add);
    my$revc_reg5_10 = revcom($reg_seq5_10);

    my   $cmd_5_10 = "$script_dir/needle $ref_seq5 $revc_reg5_10 > needle.tmp";
    my($base_pair, $miRNA_star, $miRNA) = align($cmd_5_10) ;

   # If region is a putative miRNA, then the extension by 10nt should not greatly affect the overall
   # proportion of base-pairing 

    if ( $base_pair >  $MIN_BP_EXTENDED ) {
	$counter_5 ++;
	$ret_string =  "there are $base_pair base pairs after +10nt\n";
	$ret_string .=  "\n+10nt alignment is \n\t$miRNA\n\t$miRNA_star\n\n";
    } else {
	$ret_string = "";
    }
    return $ret_string;

}
#########################################################
#########################################################
#########################################################
sub miRNA_5 {


# Obtain the reverse complement of miRNA with an additional 10 nt to check for the ability of
# hairpin to extend for Dicer cleavage.

    my $reg_seq3_10 = uc substr ($chromosome_sequence, $reg_from-$nt_add, $reg_to-$reg_from+$nt_add);
    my $revc_reg3_10 = revcom($reg_seq3_10);
    my   $cmd_3_10 = "$script_dir/needle $ref_seq3 $revc_reg3_10 > needle.tmp";

    my ($base_pair, $miRNA_star, $miRNA) = align($cmd_3_10);

    if ( $base_pair > $MIN_BP_EXTENDED ) {
	$counter_3 ++;
	$ret_string = "there are $base_pair base pairs after +10 nt\n";
	$ret_string .= "\n+10nt alignment is \n\t$miRNA\n\t$miRNA_star\n\n";
    } else {
	$ret_string = "";
    }
    return $ret_string;


}
#########################################################
#########################################################
#########################################################
sub align {
    my ($cmd, $base_pair, $seq5, $seq3, @almt_lines, $a, $b);

    my @array = @_;
    $cmd = $array[0];


    if (! system $cmd ){ 
       #block should only execute if system is successful.
       # process the output of needle ( check out needle.tmp file)
       # count the numbers of aligned bases that can form base pairs, taking into account G:U wobble.

	$base_pair = 0; 
        $seq5 = "";
        $seq3 = "";
	@almt_lines = split "\n", `cat needle.tmp`;
	foreach (@almt_lines) {
	    last if ( /\d/ );
	    chomp;
	    ($a, $b) = split " ";
	    if ($a eq $b) { 
		$base_pair ++; 
	    } #elsif ($b eq "A" && $a eq "G") { 
	#	$base_pair ++;
	    #} elsif ($b eq "C" && $a eq "T") { 
	#	$base_pair ++;
	    #}
	    $seq5 .= $a;
	    $seq3 .= $b;
	}

 
	return ($base_pair, $seq5, $seq3);
    }

} #close sub align subroutine

#########################################################
#########################################################
#########################################################
sub calculate {

    my $hit;
    my ($from, $to, $count);
    my ($length, $length_sq);
    my $total = 0;
    my ($avg, $avg_sq) = (0,0);
    my ($avg_mid, $avg_mid_sq) = (0,0);
       
    ($first_origin, $first_end) = ($from, $to, $count, $qry) = split " ", $Blossom[0]; 

    foreach $hit ( @Blossom ) {
	   ($from, $to, $count, $qry) = split " ", $hit;

	   $from -= $first_origin;
	   $to   -= $first_origin;

	   $length    = $to - $from + 1; 
	   $length_sq = $length*$length;
	   $avg      += $length*$count; 
	   $avg_sq   += $length_sq*$count; 

           $total += $count;

           $mid_seq     = ($to + $from)/2;
           $mid_sq      = $mid_seq*$mid_seq;
	   $avg_mid    += $mid_seq*$count; 
	   $avg_mid_sq += $mid_sq *$count;
       }
       $avg        /= $total;
       $avg_sq     /= $total;
       $avg_mid    /= $total;
       $avg_mid_sq /= $total;

    $length_stdev = sqrt($avg_sq - $avg*$avg);
    $avg_mid_stdev = sqrt($avg_mid_sq - $avg_mid*$avg_mid);

    if ($length_stdev > 2 || $avg_mid_stdev > 2 ) {return 0;}
    elsif ($total < 15 ) {return 0;}
    else{
	$region_hits[$region_counter] = $total;
	$region_avg_length[$region_counter]   = sprintf "%4.1f", $avg;
	$region_length_stdev[$region_counter] = sprintf "%4.1f", $length_stdev;
	$region_avg_mid[$region_counter]      = sprintf "%4.1f", ($avg_mid+$first_origin);
	$region_avg_mid_sq[$region_counter]   = sprintf "%4.1f", $avg_mid_stdev;
	return 1;
    }

}

#########################################################
#########################################################
#########################################################
sub output_calculate{

    my $last_element = $#Blossom;
    my ($last_origin, $last_end) = split " ", $Blossom[$last_element]; 

    print DATA "\n\n";
    print DATA "results for region = $region_counter\n";
    print DATA "start of overlap is from $first_origin...$first_end to $last_origin...$last_end\n";

    print DATA "total hits = $region_hits[$region_counter]\n";
    print DATA "average length = $region_avg_length[$region_counter] ".
	"p/m  $region_length_stdev[$region_counter]\n";

    print DATA "average mid position =  $region_avg_mid[$region_counter] ".
	"p/m  $region_avg_mid_sq[$region_counter]\n";

}

#########################################################
#########################################################
#########################################################
sub check_distance (@) {

    my ($prev_from, $prev_to, $tfrom, $tto) =  @_;

    if ($prev_from == 0 ) {
	return "first";

    }  elsif ($prev_to - $tfrom  > 0  )  
# $prev_to - $tfrom  >= 0 would means overlap by 1 nucleotide,
# which we do not consider as an overlap. 
# needs refinement. 
{
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


