#!/usr/bin/perl -w


$genome_dir    = "/home/ivanam/projects/colabs/Vivek/mirna/genomes/genome_hs";
$current_input = "filtered_EX2.fasta";

($no_entries) = split " ", `grep \'>\' $current_input | wc -l`;
$no_lines = 2*$no_entries;

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

	    $cmd = "megablast -d $genome_dir/$chromosome/$chromosome.fa -i tmp.fasta ".
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
