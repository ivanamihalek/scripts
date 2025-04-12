#! /usr/bin/perl

sub make_node    (@_);
sub print_tree   (@_);
sub process_afa  (@_);
sub find_endgaps (@_);
 
( @ARGV == 1 ) ||
    die "Usage: profile_almt.pl <afa paths file>.\n";

$afa_stats   = "/home/ivanam/c-utils/afa_stats";
$mafft       = "/usr/local/bin/mafft-linsi";
$extract_afa = "/home/ivanam/perlscr/extractions/extr_seqs_from_fasta.pl";

#read in the list of the alignments
$afa_list_file = $ARGV[0];
open ( IF, "<$afa_list_file" ) ||
    die "Cno $afa_list_file: $!.\n";

@afa_files = ();
while ( <IF> ) {
    chomp;
    next if ( ! /\S/ );
    push @afa_files, $_;
}
close IF;


if ( @afa_files ==1 ) {
    print "From profile_almt.pl: only one".
	" afa present in $afa_list_file: $afa_files[0] \n";
    die;
}
print "files: ", $#afa_files +1, "\n";

#run something like UPGMA:
# find the best aligned pair, and keep its mutual alignment
# (drop the original two)
# the quality of the alignment: gap counter?
$scratch = "profile_almts";
( -e $scratch) || `mkdir $scratch`;

#start the tree:
# each file represents a leaf:
$leaf = 1;
$ctr = 0;
foreach $afa_file (@afa_files) {
    @aux = split '\/', $afa_file;
    @aux = split '\.', pop @aux;
    $family = shift @aux;
    $node{$family} = make_node ($leaf, undef, undef, $family);
    printf " %4d  %s\n", $ctr,  $family;
    $ctr++;
}

$yadda = 0;
$file_ctr = 0;
while (@afa_files > 1 ) {
    $least_gaps = 5;
    @closest = ();
    $closest_file = "";
    $closest_gaps = -1;
    #$max_sim_columns = -1;
    $min_gap_solumns = 200000;

    for ($ctr1=0; $ctr1 < @afa_files; $ctr1++) {
	$file1 = $afa_files[$ctr1];
	($length1, $gaps1, $sim_columns1) = process_afa ($file1);

	$name_file1 = "names1";
	`grep \'>\' $file1 | sed \'s/>//g\' >  $name_file1`;

	for ($ctr2 = $ctr1+1; $ctr2 < @afa_files; $ctr2++) {
	    $file2 = $afa_files[$ctr2];
	    ($length2, $gaps2, $sim_columns2) = process_afa ($file2);

	    $name_file2 = "names2";
	    `grep \'>\' $file2 | sed \'s/>//g\' >  $name_file2`;
	    
	    # muscle profile almt
	    $file_ctr ++;
	    $outfile = "$scratch/profile.$file_ctr.afa";
	    $cmd  = "$mafft --seed $file1 --seed  $file2 ";
	    $cmd .= " /dev/null > $outfile ";
	    (system $cmd) &&   die "Error running $cmd\n";
	    # get rid of the _seed_ crap in the names
	    $cmd = "sed \'s/_seed_//g\' $outfile -i";
	    (system $cmd) &&   die "Error running $cmd\n";

	    ($length, $gaps, $sim_columns) = process_afa ($outfile);

	    # extract the two groups from the profile alignments
	    # and count the endgaps
	    $endgaps1 = find_endgaps ( $outfile, $name_file1);
	    $endgaps2 = find_endgaps ( $outfile, $name_file2);

	    # length change, discounting endgaps
	    $delta_l1 =  $length-$length1-$endgaps1;
	    $delta_l2 =  $length-$length2-$endgaps2;
	    print "$ctr1  $ctr2  len:$length   gap:$gaps   sim:$sim_columns ".
		" endgaps: $endgaps1 $endgaps2   length_change: $delta_l1  $delta_l2 \n";


	    
	    $new_gap_columns = $delta_l1 + $delta_l2;
	    # if closest, keep track 
            # if there is a tie, consider gaps
	    if ( $new_gap_columns < $min_gap_solumns  ) {

		$min_gap_solumns =  $new_gap_columns;
		@closest = ( $ctr2, $ctr1); # larger first, 
                                            # otherwise  splicing won't work
		$closest_gaps  = $gaps;
		$closest_file  = $outfile;
		$closest_stats = "len:$length   gap:$gaps   sim:$sim_columns ".
		    " length_change: $delta_l1  $delta_l2 \n";
		$closest_distance = (1-$sim_columns)/2;
		$closest_stats_label = 
		   int(100*$sim_columns)."_".  int(100*$gaps);
	    } 
          
	}
    }
    
    
    foreach ($ctr=0; $ctr < 2; $ctr++) {
	$cl = $closest[$ctr];
	@aux = split '\/', $afa_files[$cl];
	@aux = split '\.', pop @aux;
	$family[$ctr] = $aux[0];
	splice @afa_files, $cl,1;
	print "taking out $cl; files left : ", $#afa_files +1, "\n";
    }
    $joint_name = join ('_', @family);
    $new_name = "$scratch/$joint_name.afa";
    $cmd = "mv $closest_file $new_name";
    system ($cmd) &&
	die "Error running $cmd\n";
    push @afa_files, $new_name;
    print "adding $new_name; files left : ", 
    $#afa_files +1, "\n";
    print "$closest_stats\n";
    print "***********\n";
    $node { $joint_name } =
	make_node (0, $node{$family[0]},  
		   $node{$family[1]}, $closest_stats_label);
    $node{$family[0]}->{DISTANCE} = $closest_distance;
    $node{$family[1]}->{DISTANCE} = $closest_distance;
    print "joining  @family into $joint_name \n\n";

    `rm -f  $scratch/profile*afa`;
    
    $yadda ++;

}

print " $new_name  @closest  \n$closest_stats\n";

$cmd = "mv $new_name profile.afa";
system ($cmd) &&
    die "Error running $cmd\n";

print_tree ( $node{$joint_name});
print "\n";


#####################################################
sub find_endgaps (@_){
    my ($outfile, $name_file) = @_;
    my $ret;
    my @lines;
    my ($max_left_endgaps,  $left_endgaps);
    my ($max_right_endgaps, $right_endgaps);
    my $str;

   
    $ret = `$extract_afa $name_file $outfile`;
    @lines = split "\n", $ret;

    $str = "";
    $max_left_endgaps = 200000;
    $max_right_endgaps = 200000;

    foreach $line (@lines ) {
	if ( $line =~ /^>/ ) {
	    if ($str ) { 
		@aux = split "", $str;

		$left_endgaps = 0;
		while ( shift @aux eq "." ) {
		    $left_endgaps ++;
		}
		($max_left_endgaps > $left_endgaps) &&
		    ($max_left_endgaps = $left_endgaps);

		$right_endgaps = 0;
		while ( pop @aux eq "." ) {
		    $right_endgaps ++;
		}
		($max_right_endgaps > $right_endgaps) &&
		    ($max_right_endgaps = $right_endgaps);


	    }
	    $str = "";
	} else {
	    $line =~ s/\-/./g;
	    $str .= $line;
	}

    }
    if ($str ) { 
	@aux = split "", $str;

	$left_endgaps = 0;
	while ( shift @aux eq "." ) {
	    $left_endgaps ++;
	}
	($max_left_endgaps > $left_endgaps) &&
	    ($max_left_endgaps = $left_endgaps);

	$right_endgaps = 0;
	while ( pop @aux eq "." ) {
	    $right_endgaps ++;
	}
	($max_right_endgaps > $right_endgaps) &&
	    ($max_right_endgaps = $right_endgaps);
	

    }

    return $max_left_endgaps+$max_right_endgaps;
}



#####################################################
sub process_afa (@_){

    my $outfile = $_[0];
    my $ret;
    my @lines;
    my ($kwd, $val);
    my ($length, $gaps, $sim_columns);

    $ret = `$afa_stats  $outfile`;
    @lines = split "\n", $ret;


    foreach  ( @lines ) {
	($kwd, $val) = split;
	($kwd =~ /aln_length/) && ($length = $val );
	($kwd =~ /pct_gaps/) && ( $gaps = $val );
	($kwd =~ /pct_similar_columns/) && ( $sim_columns = $val );
    }

    return ($length, $gaps, $sim_columns);
}

#####################################################
sub print_tree (@_) {

    my $node = $_[0];
    if ( $node->{LEAF} ) {
	print  "$node->{VALUE}:$node->{DISTANCE}";
	return;
    }
    print "(";
    print_tree ($node->{LEFT});
    print ",";
    print_tree ($node->{RIGHT});
    print ")";
    if ( defined $node->{VALUE} ) {
	print "$node->{VALUE}";
    }
    print  ":$node->{DISTANCE}";

    return;
}


#####################################################
sub make_node (@_) {
    
    my ($leaf, $left, $right, $value) = @_;
    my $node;
    $node = {};
    $node->{LEAF}   = $leaf;
    $node->{LEFT}   = $left;
    $node->{RIGHT}  = $right;
    $node->{VALUE}  = $value;
    $node->{DISTANCE} = 0.0;
    return $node;
}
#####################################################
