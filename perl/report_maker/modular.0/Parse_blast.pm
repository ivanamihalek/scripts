#! /usr/bin/perl -w

use strict;

use Carp; # carping and croaking

our $id;
our %options;
our (%path, %is_segment, %is_hi_id, @unique_chains, %copies);   
our (%start, %end, %pid);
our @regions;

our $FRAGMENT_LENGTH;
our $TOO_FEW_SEQS;
our $TOO_SHORT;
our $MAX_ID;
our $PID_IDENTICAL;
our $PID_LOWEST_ACCEPTABLE;

################################################################################################

sub segment_1_is (@);
sub find_workable_regions (@);

################################################################################################
sub blast2fasta (@) {
    my ($query_name, $seq, $use_heuristics ) = @_;
    my ($blastout, $blast, $ctr,  %bitval);
    my ($line, @lines);
    my ($name, @sorted_names);
    my ($prev_bitval, $reading, $jump);
    my ($file, $fh, $fastafile);
    my ($query_id, $subject_id,  $pct_identity, $alignment_length, 
	$mismatches, $gap_openings, $q_start, $q_end, $s_start, $s_end, $e_value, $bit_score)    = ();
    my $query_length = length $seq;
    my $command;
    my $no_seqs;
    my ($no_points, $cumulative, $avg);
    my @all_ids;
    my @fasta_files = ();
    my %already_seen;
    printf "\t\tin blast2fasta\n";

    $fastafile = "$query_name.fasta";
    return ("full", $fastafile) if ( -e $fastafile &&  -s $fastafile);

    # blast against database and print the output
    $blastout =  "$query_name.uniprot.blastp";
    (-e $blastout && -s $blastout) || do_blast ($seq, $query_name, $path{"uniprot_for_blast"},  $path{"blast"}, 8,  $blastout);

    if ( ! -s $blastout ) {
	print "\t\tno matches in uniprot\n";
	return ("");
    } 

    open ( IF, "<$blastout" ) ||
	die "Error: From parse_blast_8: Cno $blastout: $!.\n";
    #slurp in the input as a single string
    undef $/;
    $blast = <IF>;
    $/ = "\n";
    close IF;
   
    @lines  =  split '\n', $blast;
    if (@lines < $TOO_FEW_SEQS) {
	print "\t\t too few seqs in blast: ", `wc -l $blastout`;
	return ("");
    }

    $ctr = 0;
    @all_ids = ();
    %already_seen = ();
    foreach $line ( @lines ) {
	($query_id, $subject_id,  $pct_identity, $alignment_length, 
	 $mismatches, $gap_openings, $q_start, $q_end, $s_start, $s_end, $e_value, $bit_score) =
	     split '\s', $line;
	if ( ! defined $already_seen{$subject_id} ){
	    push @all_ids, $subject_id;
	    $already_seen{$subject_id} = 1;
	}
        next if ( $alignment_length/$query_length < $FRAGMENT_LENGTH );
	if ( ! defined  $bitval{$subject_id} ) {# the first mention has the highest  bitval
	    $bitval{$subject_id} =  $bit_score; 
	    $ctr++;
	}
    }
     
     # heurisitcs:
    $no_seqs = 0;
    foreach ( keys %bitval ) {
	$no_seqs ++;
    }
    if ($no_seqs <  $TOO_FEW_SEQS) {
	@regions = find_workable_regions ($blast);
	if ( ! @regions  ) { 
	    print "\t\t too few seqs returned from blast (which are not fragments) $no_seqs\n";
	    return ("");
	} 
	$file = "$query_name.names";
	$fh = outopen ($file);
	foreach ( @all_ids) {
	    print $fh  "$_\n";
	}
	$fh->close;
    } else {
	$file = "$query_name.names";
	$fh = outopen ($file);
	foreach ( keys %bitval ) {
	    print $fh  "$_\n";
	}
	$fh->close;
    } 

    run_fastacmd ($file, $path{"uniprot_for_blast"}, "tmp.fasta"); 
    fasta_names_simplify ("tmp.fasta"); 

    if ( !@regions ) {
	# add the query
	if (defined $options{"MODEL"}) {
	    `cat $id.seq >> tmp.fasta`;  
	} else {
	    `cat $query_name.seq >> tmp.fasta`;  
	}
	# remove identical seqs
	# align with muscle
	$command = $path{"muscle"}." -in tmp.fasta -out tmp.afa -maxiters 3 >& /dev/null";
	(system $command) &&  die "Error: $command\nError running muscle.";
	$command = $path{"remove_id_from_afa"}."  tmp.afa  tmp.2.afa $query_name $MAX_ID ";
	(system $command) && die "Error: $command\nError running remove_id_from_afa.";
	`mv tmp.2.afa $fastafile`;
	`rm tmp.fasta tmp.afa`;
	push @fasta_files, "full";
	push @fasta_files, $fastafile;
    } else {
	my ($region_start, $region_end, $region, $avg_no_seqs);
	my  ($s, @seqs);
	my @whole_fasta;
	my $subject_seq;
	my @aux;
	my %fasta;
	my $entry;
	my $reg_ctr;
	print "\t\tanother run through blast output\n";
	@whole_fasta = split '>', `cat tmp.fasta`;
	shift 	@whole_fasta; # first piece before ">"  is empty
	foreach $entry (@whole_fasta) {
	    @aux = split '\n', $entry;
	    $name = shift @aux;  $name =~ s/\s//g;
	    $subject_seq = join "", @aux; $subject_seq =~ s/\s//g;
	    $fasta{$name}= $subject_seq;
	} 

	foreach( $reg_ctr=$#regions; $reg_ctr >= 0; $reg_ctr-- ) { # backwards, so I can splice
	    $region = $regions[$reg_ctr];
	    # assemble fasta piece by piece
	    ($region_start, $region_end,  @seqs) = split " ", $region;
	    $file = "$query_name.$region_start.$region_end.fasta"; 
	    $fh = outopen ($file);
	    print $fh "> $query_name\n";
	    print $fh  (formatted_sequence (substr $seq, $region_start-1, $region_end-$region_start+1));
	    print $fh "\n";
	    foreach $s (@seqs ) {
		($subject_id, $s_start, $s_end) = split '#', $s;
		if ( ! defined $fasta{$subject_id} ) {
		    print "$subject_id\n";
		    exit;
		}
		print $fh "> $subject_id\n";
		print $fh  (formatted_sequence (substr $fasta{$subject_id}, $s_start-1, $s_end-$s_start+1));
		print $fh "\n";
	    }
	    $fh->close;  
	    # align using muscle
	    $command = $path{"muscle"}." -in $file -out tmp.afa -maxiters 3 >& /dev/null";
	    (system $command) &&  die "Error: $command\nError running muscle.";
	    # remode identical
	    $command = $path{"remove_id_from_afa"}."  tmp.afa  tmp.2.afa $query_name $MAX_ID ";
	    (system $command) && die "Error: $command\nError running remove_id_from_afa.";
	    # clip the alignment to more or less the region length
	    # rename
	    `mv tmp.2.afa $file`;
	    `rm tmp.afa`;
	    # count how many I have left
	    $no_seqs = `grep \'>\' $file | wc -l`;
	    chomp $no_seqs;
	    if ($no_seqs <  $TOO_FEW_SEQS) {
		print " \t\t too few seqs for the region $region_start-$region_end.\n"; 
		splice @regions, $reg_ctr, 1;
	    } 
	} 
	# for the ones with enough seqs, proceed to peacemeal analysis 
	push @fasta_files, "region";
	print "\t\tregions left:\n";
	foreach $region (@regions) {
	    ($region_start, $region_end,  @seqs) = split " ", $region;
	    print " \t\t\t$region_start   $region_end  \n";
	    push @fasta_files, $file;
	}
    }
    return @fasta_files;   
}
 
################################################################################################  
sub find_workable_regions (@) {
    my $blast = $_[0]; 
    my @lines; 
    my ($query_id, $subject_id,  $pct_identity, $alignment_length,  
	$mismatches, $gap_openings, $q_start, $q_end,  
	$s_start, $s_end, $e_value, $bit_score) = (); 
    my ($ctr, @cover, @regions,  $region_start, $region_end, $counting);
    my $region; 
    my %seqs; 
    my %already_seen;
    print " \t\t\tlooking for usable regions \n";

    @lines  =  split '\n', $blast; 
    foreach ( @lines) {
	($query_id, $subject_id,  $pct_identity, $alignment_length, 
	 $mismatches, $gap_openings, $q_start, $q_end, 
	 $s_start, $s_end, $e_value, $bit_score) = split;
	last if ( $e_value > 1.e-10);
	for ($ctr= $q_start; $ctr <=$q_end; $ctr++) {
	    defined $cover[$ctr] || ($cover[$ctr]=0);
	    $cover[$ctr] ++;
	}
    }

    foreach $ctr ( 1 .. $#cover ) {
	defined  $cover[$ctr] || ( $cover[$ctr] = 0);
    }


    #region = more than $TOO_SHORT consecutive positions covered by > $TOO_FEW_SEQS seqs
    $region_start = -1;
    $counting = 0;

    foreach $ctr ( 1 .. $#cover ) {
	if ( $cover[$ctr] >= $TOO_FEW_SEQS ) {
	    if ( !$counting ) {
		$counting = 1;
		$region_start = $ctr;
	    }
	} else {
	    if ( $counting ) {
		$region_end = $ctr - 1;
		if (  $region_end - $region_start + 1 > $TOO_SHORT) {
		    push @regions, "$region_start   $region_end ";
		}
	    }
	    $counting = 0; 
	}
    }
    if ( $counting ) {
	$region_end = $ctr - 1;
	if (  $region_end - $region_start + 1 > $TOO_SHORT) {
	    push @regions, "$region_start   $region_end ";
	}
    }

    # another pass to get rid of nonsense overlaps
    foreach $region( @regions ) {
	@{$seqs{$region}} = ();
    }
    %already_seen = ();
    foreach ( @lines) {
	($query_id, $subject_id,  $pct_identity, $alignment_length, 
	 $mismatches, $gap_openings, $q_start, $q_end, 
	 $s_start, $s_end, $e_value, $bit_score) = split;
	last if ( $e_value > 1.e-10);
	foreach $region ( @regions ) {
	    ($region_start, $region_end) = split " ", $region;
	    if ( (!defined $already_seen{$region}{$subject_id})  &&
		 segment_1_is ($q_start, $q_end, $region_start, $region_end, 0.1) ne "disjoint" ) {
		push @{$seqs{$region}}, join '#', ($subject_id, $s_start, $s_end);
		$already_seen{$region}{$subject_id} = 1;
	    } 
	}
    }
    print "\t\tregions:\n";
    foreach ( @regions ) {
	print "\t\t\t$_ \n";
    }
    for $ctr ( 0 .. $#regions) {
	$region = $regions[$ctr];
	$regions[$ctr] .= " @{$seqs{$region}}";
    }
    return @regions;

}

################################################################################################
sub parse_blast_8_on_uniprot ( @) {

    my $filename = shift @_;
    my ($query_id, $subject_id,  $pct_identity, $alignment_length, 
     $mismatches, $gap_openings, $q_start, $q_end, $s_start, $s_end, $e_value, $bit_score)    = ();
    my ($blast, $line);
    my ($uniprot_descr , $ret, $uniprot_id);
    my @aux;

    open ( IF, "<$filename" ) ||
	die "Error: From parse_blast_8: Cno $filename: $!.\n";
    #slurp in the input as a single string
    undef $/;
    $blast = <IF>;
    $/ = "\n";
    close IF;

    ($line)  =  split '\n', $blast; # --> we are interested only in the first return
    $line || return ("", "");
    ($query_id, $subject_id,  $pct_identity, $alignment_length, 
     $mismatches, $gap_openings, $q_start, $q_end, $s_start, $s_end, $e_value, $bit_score) =
	 split '\s', $line;

    # find the main key for uniprot 
    $uniprot_descr =  `$path{"db_ret"}  $path{"uniprot"}  $subject_id`;
    if ( ! $uniprot_descr ||  $uniprot_descr =~ /not found/)  {
	$ret =  `$path{"db_ret"}  $path{"var2uni"}  $subject_id`; 
	if ( $ret =~ /not found/i ) {
	    # some desperate measures: assume it's something like Q56K07_BOVIN 
	    @aux = split '_', $subject_id;
	    $ret =  `$path{"db_ret"}  $path{"var2uni"}  $aux[0]`;
	    ( $ret =~ /not found/i ) && return ("", 0);
	}
	@aux = split '\n', $ret;
	$uniprot_id = "";
	while ( @aux  &&  !$uniprot_id ) { $uniprot_id = pop @aux; }
	
    }
    $uniprot_descr =  `$path{"db_ret"}  $path{"uniprot"}  $uniprot_id`;
    ( $uniprot_descr =~ /not found/) && ( $uniprot_descr = "" );
    return ($uniprot_descr,$pct_identity);
}



################################################################################################
sub parse_blast_8_on_pdb ( @) {


    my $query_length = shift @_;
    my $filename = shift @_;
    my (@aux, $chain_name);
    my @real_deal = ();
    my @model = ();
    my @piece = ();
    my @model_piece = ();
    my @other_chains = ();
    my ($query_id, $subject_id,  $pct_identity, $alignment_length, 
     $mismatches, $gap_openings, $q_start, $q_end, $s_start, $s_end, $e_value, $bit_score)    = ();
    my ($blast, $line);
    my $coverage;
    
    open ( IF, "<$filename" ) ||
	die "Error: From parse_blast_8: Cno $filename: $!.\n";
    #slurp in the input as a single string
    undef $/;
    $blast = <IF>;
    $/ = "\n";
    close IF;


    foreach $line ( split '\n', $blast ) {
	 ($query_id, $subject_id,  $pct_identity, $alignment_length, 
	 $mismatches, $gap_openings, $q_start, $q_end, $s_start, $s_end, $e_value, $bit_score) =
	     split '\s', $line;
	 if (  $subject_id =~ /\|/ ) {
	     @aux = split '\|', $subject_id;
	     $chain_name = join "", ( lc $aux[$#aux-1], uc $aux[$#aux]);
	 } elsif (  $subject_id =~ /_/ )  {
	     @aux = split '_', $subject_id;
	     $chain_name = lc $aux[0];
	     ( defined $aux[1] && $aux[1] )  && ( $chain_name .= uc $aux[1]);
	 } else {
	     croak "Error: unrecognized sequence identifier format.";
	 }
	 ( length $chain_name ==4 ||  length $chain_name ==5 ) || 
	     die "Error: error parsing blastp - expecting PDB names: $chain_name.";

	 $start{$chain_name} = $q_start;
	 $end{$chain_name}   = $q_end;
	 $pid{$chain_name}   = $pct_identity;
	 
	 if ( $alignment_length/$query_length > $PID_IDENTICAL/100 ) { 
	     $is_segment{$chain_name} = 0;
	     if ( $pct_identity > $PID_IDENTICAL ) { 
		 push @real_deal, $chain_name;
		 $is_hi_id{$chain_name} = 1;
	     } elsif ( $pct_identity > $PID_LOWEST_ACCEPTABLE) { 
		 push @model, $chain_name;
		 $is_hi_id{$chain_name} = 0;
	     } 
	 } else {
	     $is_segment{$chain_name} = 1;
	     if ( $pct_identity > $PID_IDENTICAL ) {
		 push @piece, $chain_name;
		 $is_hi_id{$chain_name} = 1;
	     } elsif  ( $pct_identity > $PID_LOWEST_ACCEPTABLE){  
		 push @model_piece, $chain_name;
		 $is_hi_id{$chain_name} = 0;
	     } 
	 }
    }

    (@real_deal ||  @model ||  @piece ||  @model_piece)  || return 0;
    
    if (@real_deal) {
	$chain_name = shift @real_deal;
	push @unique_chains, $chain_name;	
	@ { $copies{$chain_name} } =  (@real_deal, @model, @piece, @model_piece);
	$coverage = 1;
	print "@unique_chains\n";
    } elsif (@model) {
	$chain_name = shift @model;
	push @unique_chains, $chain_name;	
	@ { $copies{$chain_name} }  =  (@model, @piece, @model_piece);	
	print "@unique_chains\n";
	$coverage = 1;
    } elsif ( @piece || @model_piece ) {
	my (@segments, @prototype, $new_segment, $seg1_is);
	my ($segment, $ctr, $s, $e);

	# find which nonoverlapping pieces I have to begin with
	# use the longest real if possible as the original
	@segments = ();
	foreach  $chain_name (@piece, @model_piece) {
	    if ( ! @segments ) {
		$segments[0] = "$start{$chain_name}   $end{$chain_name}";
		$prototype[0] = $chain_name;
		next;
	    }
	    $new_segment = 1;
	    foreach $ctr ( 0 ..  $#segments ) {
		$segment = $segments[$ctr];
		($s, $e) = split " ", $segment;
		$seg1_is = segment_1_is ($s, $e, $start{$chain_name} , $end{$chain_name}, 0.5);
		# low id piece cannot replace hi id piece:
		if ( $is_hi_id{$prototype[$ctr]} && ! $is_hi_id{$chain_name} &&   $seg1_is ne "disjunct" ) {
		    $new_segment = 0;
		    push @{$other_chains[$ctr]}, $chain_name;
		    last;
		} elsif ( $seg1_is eq "superset" ) {
		    $new_segment = 0;
		    push @{$other_chains[$ctr]}, $chain_name;
		    last;
		} elsif ( $seg1_is eq "subset" ){
		    $new_segment = 0;
		    $segments[$ctr] = "$start{$chain_name}   $end{$chain_name}";
		    push @{$other_chains[$ctr]}, $prototype[$ctr];
		    $prototype[$ctr] = $chain_name;
		    last;
		    
		}
	    }
	    if ( $new_segment ) {
		push @segments,  "$start{$chain_name}   $end{$chain_name}";
		push @prototype,  $chain_name;
	    }
	}
	$coverage = 0;
	foreach $ctr(0 .. $#prototype ) {
	    $chain_name = $prototype[$ctr];
	    $unique_chains[$ctr] = $chain_name;
	    $coverage += $end{$chain_name} - $start{$chain_name} + 1;
	    if (defined $other_chains[$ctr] ){
		@{$copies{$chain_name}} =  @{$other_chains[$ctr]};
	    } else {
		@{$copies{$chain_name}} = ();
	    }
	}
	$coverage /= $query_length;
    }

    return $coverage;
    
}

######################################################################
sub  segment_1_is (@) {
    my ($s1, $e1, $s2, $e2, $fraction) = @_;
    my ($overlap, $l1, $l2);
    # "clean" cases
    ( $s2 >= $e1 || $s1 >= $e2 ) &&  return "disjoint";
    ( $s1 <= $s2 && $e1 >= $e2 ) &&  return "superset";
    ( $s2 <= $s1 && $e2 >= $e1 ) &&  return "subset";

    # overlaps - some arbitrariness here ...
    if ( $e1 >= $s2 ) {
	$overlap = $e1 - $s2 +1;
	$l1 = $e1 - $s1+ 1;
	$l2 = $e2 - $s2 + 1;;
	( $overlap/$l1 < $fraction &&  $overlap/$l2 < $fraction )  && return "disjoint";
	( $overlap/$l1 < $fraction )  &&  return "superset";
	return "subset";
    }

    if ( $e2 >= $s1 ) {
	$overlap = $e2 - $s1 +1;
	$l2 = $e2 - $s2+ 1;
	$l1 = $e1 - $s1 + 1;;
	( $overlap/$l2 < $fraction &&  $overlap/$l1 < $fraction ) &&  return "disjoint";
	( $overlap/$l2 < $fraction )  &&  return "subset";
	return "superset";
    }

    die "Error in segment_1_is()";
}




1;
