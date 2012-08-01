#!/usr/bin/perl -w

use Switch;

sub needleman_wunsch (@);

$FAR_FAR_AWAY =  -10000;


############################################
(@ARGV == 2) || die "Usage: $0 <pdb1> <pdb2>\n";
@pdbs = @ARGV;

############################################
%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
           'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
           'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
               'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E', 'PTR', 'Y' ); 


############################################
# extract CAs
for $i (0 .. 1) {
    
    $pdb = $pdbs[$i];
    (-e $pdb) || die "$pdb not found.\n";
    $cmd = "awk \'\$1==\"ATOM\" && \$3==\"CA\"\' $pdb";
    $CAs[$i] = `$cmd`;
}

############################################
# make dist_matrix/sim_matrix
$ctr[0] = 0;

foreach $line0 ( split "\n", $CAs[0] ) {
    # extract the  vectors
    $r0[0] = substr $line0, 30, 8;  $r0[0] =~ s/\s//g;
    $r0[1] = substr $line0, 38, 8;  $r0[1] =~ s/\s//g;
    $r0[2] = substr $line0, 46, 8;  $r0[2] =~ s/\s//g;

    #store the sequence while we are at that
    $res_name = substr $line0,  17, 4; $res_name=~ s/\s//g;
    $seq[0][$ctr[0]] = $letter_code{$res_name};

    $ctr[1] = 0;
    foreach $line1 ( split "\n", $CAs[1] ) {
	# extract the  vectors
	$r1[0] = substr $line1, 30, 8;  $r1[0] =~ s/\s//g;
	$r1[1] = substr $line1, 38, 8;  $r1[1] =~ s/\s//g;
	$r1[2] = substr $line1, 46, 8;  $r1[2] =~ s/\s//g;

	if ( ! $ctr[0] ) { # we have to do it only once
	    #store the sequence while we are at that
	    $res_name = substr $line1,  17, 4; $res_name=~ s/\s//g;
	    $seq[1][$ctr[1]] = $letter_code{$res_name};
	}
	$d = 0;
	for $i (0..2) {
	    $aux = $r0[$i] - $r1[$i];
	    $d += $aux*$aux;
	}
	$d = sqrt($d);
	#print "$line0\n$line1\n";
	#printf " %8.3f\n", $d; exit;
	$similarity[$ctr[0]][$ctr[1]] = exp(-($d-3.0));
	#$distance[$ctr[0]][$ctr[1]]   = $d;

	$ctr[1] ++;
    }

    $ctr[0] ++;
}
$dim1 =  $ctr[0];
$dim2 =  $ctr[1];

############################################
# run Needleman Wunsch
@map_i2j = ();
@map_j2i = ();

needleman_wunsch ($dim1, $dim2, 1);

############################################
#for $i (0.. $dim1-1) {
#    $j =  $map_i2j[$i];
#    print "$dim1  $i  $j  ";
#    if ( $j >=0 ) {
#	printf "%8.3f ", $distance[$i][$j];
#    }
#    print "\n";
#}


############################################3
# aligned seqs
$i = 0; $j = 0;
$almt_pos = 0;
while ($i< $dim1 ||  $j < $dim2 ) {
    while ($i< $dim1 &&  $map_i2j[$i] == $FAR_FAR_AWAY) {
	$aligned_seq[0][$almt_pos] = $seq[0][$i];
	$aligned_seq[1][$almt_pos] = '-';
	$almt_pos ++;
	$i ++;
    }
    while ($j < $dim2 && $map_j2i[$j] == $FAR_FAR_AWAY) {
	$aligned_seq[0][$almt_pos] = '-';
	$aligned_seq[1][$almt_pos] = $seq[1][$j];
	$almt_pos ++;
	$j ++;
    }
    if ($i< $dim1 &&  $j < $dim2 )  {
	if ( $map_i2j[$i] != $j || $map_j2i[$j] != $i ) {
	    die "alignment error (?)\n";
	}
	$aligned_seq[0][$almt_pos] = $seq[0][$i];
	$aligned_seq[1][$almt_pos] = $seq[1][$j];
	$almt_pos ++;
	$i ++;
	$j ++;
    }
	
}

$almt_length = $almt_pos;

#############################################
# output afa
for $i (0..1) {
    $name = $pdbs[$i];
    $name =~ s/\.pdb//;

    if ($i==0) {
	@map = @map_i2j;
    } else {
	@map = @map_j2i;
    }
    print ">$name\n";
    for $almt_pos (0 .. $almt_length-1) {
	print $aligned_seq[$i][$almt_pos];
	print "\n" if ( ! (($almt_pos+1)%50 ) ); 
    }
    print "\n";
    
}



######################################################################
######################################################################
######################################################################
sub needleman_wunsch (@) {

    my  ($dim_i, $dim_j, $use_endgap) = @_;

    my @F;  #alignment_scoring table
    my @direction;
    my $gap_opening   =  -0.5;
    my $gap_extension =  -0.2;
    my $endgap        =  -0.0;
    my ($i_sim, $j_sim, $diag_sim, $max_sim) = (0.0, 0.0, 0.0, 0.0) ;
    my $score = 0.0;
    my ($i,$j);
    my ($max_i,$max_j) = ($dim_i, $dim_j);
    my $penalty = 0.0;
    

    foreach $i ( 0 .. $max_i) {
	foreach $j ( 0 .. $max_j) {
	    $F[$i][$j] = 0.0;
	    $direction[$i][$j] = 0;
	}
    }
    #  fill the table 
    foreach $i ( 0 .. $max_i) {
	foreach $j ( 0 .. $max_j) {

	    if ( !$i && !$j ) { # upper left corner 
		$F[0][0] = 0;
		$direction[$i][$j] = 'd';
		next;
	    }
	    
	    if ( $i && $j ){ 
		if ( $direction[$i-1][$j] eq 'i' ) {
		    #  gap extension  */
		    $penalty = ($use_endgap&&$j==$max_j) ? $endgap : $gap_extension;		    
		} else {
		    #  gap opening  */
		    $penalty = ($use_endgap&&$j==$max_j) ? $endgap : $gap_opening;
		}
		$i_sim =  $F[$i-1][$j] + $penalty;

		
		if ( $direction[$i][$j-1] eq 'j' ) {
		    $penalty = ($use_endgap && $i==$max_i) ? $endgap : $gap_extension;		    
		} else {
		    $penalty = ($use_endgap && $i==$max_i) ? $endgap : $gap_opening;		    
		}
		$j_sim = $F[$i][$j-1] +  $penalty;
		
		
		$diag_sim =  $F[$i-1][$j-1] + $similarity [$i-1][$j-1] ;
		
	    } elsif ( $j ) {
		
		if ( $use_endgap) {
		    $penalty = $endgap;
		} else {
		    if ( $direction[$i][$j-1] eq 'j' ) {
			$penalty =  $gap_extension;
		    } else {
			$penalty =  $gap_opening;
		    }
		}
		$j_sim = $F[$i][$j-1] + $penalty;
		
		$i_sim = $diag_sim =  $FAR_FAR_AWAY;

	    } elsif ( $i ) {
		if ( $use_endgap) {
		    $penalty = $endgap;
		} else {
		    if ( $direction[$i-1][$j] eq 'i' ) {
			$penalty =  $gap_extension;
		    } else {
		        $penalty =  $gap_opening;
		    }
		}
		$i_sim = $F[$i-1][$j] + $penalty;
		
		$j_sim = $diag_sim =  $FAR_FAR_AWAY;
		
	    } 

	    $max_sim = $diag_sim;
	    $direction[$i][$j] = 'd';
	    if ( $i_sim > $max_sim ){
		$max_sim = $i_sim;
		$direction[$i][$j] = 'i';
	    }
	    if ( $j_sim > $max_sim ) {
		$max_sim = $j_sim;
		$direction[$i][$j] = 'j';
	    }

	    $F[$i][$j] = $max_sim;
	    
	}
    }

    $score = $F[$max_i][$max_j];

    #retrace*/
    $i = $max_i;
    $j = $max_j;

    while ( $i>0 ||  $j >0 ) {
	#printf (" %4d  %4d  %8.3f  \n", i, j, $F[i][j]);
	switch ( $direction[$i][$j] ) {
	    case 'd' {
		#printf ( " %4d  %4d \n",  i, j);	    
		$map_i2j [$i-1] = $j-1;
		$map_j2i [$j-1] = $i-1;
		$i--;
		$j--; 
	    }
	    case 'i' {
		#printf ( " %4d  %4d \n",  i, -1);
		$map_i2j [$i-1] = $FAR_FAR_AWAY;
		$i--; 
	    } 
	    case 'j' {
		#printf ( " %4d  %4d \n",  -1, j);
		$map_j2i [$j-1] = $FAR_FAR_AWAY;
		$j--; 
	    } 
	    else {
		die "Retracing error.\n";
	    } 
	}
    }

    return $score; 
   
    
}
