#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

($query_id, $subject_id,  $pct_identity, $alignment_length, 
 $mismatches, $gap_openings, $q_start, $q_end, 
 $s_start, $s_end, $e_value, $bit_score) = (0);


while ( <> ) {
    chomp;
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
    print "$ctr  $cover[$ctr]\n";
}


#region = more than 20 consecutive positions covered by > 10 seqs
$region_start = -1;
$counting = 0;

foreach $ctr ( 1 .. $#cover ) {
    if ( $cover[$ctr] >= 10 ) {
	if ( !$counting ) {
	    $counting = 1;
	    $region_start = $ctr;
	    $avg_number_of_seqs = 0;
	}
	$avg_number_of_seqs += $cover[$ctr];
    } else {
	if ( $counting ) {
	    $region_end = $ctr - 1;
	    $avg_number_of_seqs /= $region_end - $region_start + 1;
	    $avg_number_of_seqs = sprintf "%5.1f", $avg_number_of_seqs;
	    push @regions, "$region_start   $region_end   $avg_number_of_seqs";
	}
	$counting = 0; 
    }
}

=pod
foreach ( @regions ) {
    print "$_ \n";
}
=cut
