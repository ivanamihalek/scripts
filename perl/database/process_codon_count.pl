#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);


$process_codons = 1; # i.e. process amino acids instead

@stop_codons = ( "TAA", "TAG", "TGA" );
if ( $process_codons ) {
    #####################################################
    #  initialize  codon count
    @nts = ("A", "C", "G", "T" ); 
    @letters = ();
    for $nt1 ( @nts) {
	for $nt2 ( @nts) {
	    NT: for $nt3 ( @nts) {
		$codon = $nt1.$nt2.$nt3;
		foreach $stop_codon ( @stop_codons ) {
		    next NT if ( $codon eq $stop_codon);
		}
		push @letters, $codon;
	    }
	}
    }
    push @letters, "---";
    
    %pair_ctr = ();
    for $codon1 ( @letters) {
	for $codon2 ( @letters) {
	    $pair_ctr {$codon1." ".$codon2} = 0; 
	}
    }
} else {

    #####################################################
    #  initialize  amino acid  count
    @letters = ("A", "C", "D", "E", "F", "G", "H", "I", "K", "L", "M", 
	    "N", "P", "Q", "R", "S", "T", "V", "W", "Y", "-");
    %pair_ctr = ();
    for $aa1 ( @letters) {
	for $aa2 ( @letters) {
	    $pair_ctr {$aa1." ".$aa2} = 0; 
	}
    }
}


#####################################################
#  input
while ( <> ) {
    last if (/usable/);
}
READ: while ( <> ) {
    next if ( !/\S/ ) ;
    chomp;
    ($codon1, $codon2, $count) = split;
    if ( $process_codons ) {
	foreach $stop_codon ( @stop_codons ) {
	    next READ if ( $codon1 eq $stop_codon ||  $codon2 eq $stop_codon );
	}
    }
    if ( (length $codon1) == 3 &&  $process_codons) { 
	$pair_ctr {$codon1." ".$codon2} = $count;
    } elsif ( (length $codon1) == 1 &&  !$process_codons) {
	$pair_ctr {$codon1." ".$codon2} = $count;
    }
}


#####################################################
#  process aas

#make counts symmetric
for $letter_ctr1 ( 0 .. $#letters) {
    $letter1 = $letters[$letter_ctr1];
    for $letter_ctr2 ( $letter_ctr1+1 .. $#letters) {
	$letter2 = $letters[$letter_ctr2];
	$pair_ctr {$letter1." ".$letter2} += $pair_ctr {$letter2." ".$letter1};
	$pair_ctr {$letter2." ".$letter1}  = $pair_ctr {$letter1." ".$letter2};
    }
}

    
# how many times have I seen an amino acid type?
# initialize $letter counts
foreach $letter1 ( @letters ) {
    $letter_ctr{$letter1} = 0;
}
    
for $letter_ctr1 ( 0 .. $#letters) {
    $letter1 = $letters[$letter_ctr1];
    for $letter_ctr2 ( $letter_ctr1 .. $#letters) {
	$letter2 = $letters[$letter_ctr2];
	$pair = $letter1." ".$letter2;
	$letter_ctr{$letter1} +=  $pair_ctr{$pair};
	$letter_ctr{$letter2} +=  $pair_ctr{$pair};
    }
}


# sort amino acids by the number of times I saw them
@letter_sorted = sort  HashByValue ( @letters );
foreach $letter1 ( @letter_sorted ) {
    print "$letter1      $letter_ctr{$letter1}\n";
}


# initialize the target number of sequences to the lowest letter count
$target_no = $letter_ctr{ $letter_sorted[0] };
$remainder{$letter_sorted[0]} = 0;
# initialize the selected pairs list to pairs containing
# the letter with the lowest count
$sum += 0;
foreach $letter1 ( @letters ) {
    $pair = $letter_sorted[0]." ".$letter1;
    $select_pairs{$pair} = $pair_ctr{$pair};
    print "selected pair:   $pair   $select_pairs{$pair} \n";
    $sum += $pair_ctr{$pair};
    if ( $letter1 eq $letter_sorted[0] ) {
	$sum += $pair_ctr{$pair};
    }
}
print "\n sum =  $sum \n\n"; 

# for each letter, from second lowest in counts,  on:
for $loop_ctr ( 1 .. $#letter_sorted) {

    # which letter has the smallest remainder
    %so_far_letter_ctr = ();
    %remainder= ();
    for $letter_ctr1 ( $loop_ctr .. $#letter_sorted) {
	$letter1 = $letter_sorted[$letter_ctr1];
	$so_far_letter_ctr{$letter1} = 0;
	foreach $pair ( keys  %select_pairs ) {
	    #print "pair:  $pair \n";
	    if  ( $pair eq $letter1." ".$letter1 ){
		$so_far_letter_ctr {$letter1}  +=  2*$select_pairs{$pair};
	    } elsif ( $pair =~ $letter1 ) {
		$so_far_letter_ctr {$letter1} +=  $select_pairs{$pair};
	    }
	}
	$remainder{$letter1} = $letter_ctr{$letter1} - $so_far_letter_ctr{$letter1};
    }
    @letter_sorted[$loop_ctr .. $#letter_sorted]  = sort  HashByValue2 ( @letter_sorted[$loop_ctr .. $#letter_sorted] );
=pod
    foreach $letter1 ( @letter_sorted ) {
	print "$letter1      $remainder{$letter1}\n";
    }
    print "\n\n";
=cut
    $letter1 = $letter_sorted[$loop_ctr];
    #printf "$letter1  seen 	$so_far_letter_ctr   times.\n";

    # difference btw that number and the target_no 
    $fraction = ($target_no - $so_far_letter_ctr{$letter1}) /($letter_ctr{$letter1} - $so_far_letter_ctr{$letter1});
    printf "$letter1  seen  $so_far_letter_ctr   times  - remainder: $remainder{$letter1}.";
    printf " fraction: %8.3f \n", $fraction;

    # select proportional fraction from each unseen pair and
    # add it to the seen list

    $sum = $so_far_letter_ctr{$letter1};

    for $letter_ctr2 ( $loop_ctr .. $#letter_sorted) {
	$letter2 = $letter_sorted[$letter_ctr2];
	if ( $letter1 eq $letter2 ) {
	    next;
	}
	$pair = $letter1." ".$letter2;
	$sum += $pair_ctr{$pair}*$fraction;
	$select_pairs{$pair} =  $pair_ctr{$pair}*$fraction;
	#printf "\t $letter2   %5d   %8.3f   %8.3f  \n",  $pair_ctr{$pair}, 
	$pair_ctr{$pair}*$fraction, $sum;
    }
    $pair = $letter1." ".$letter1;
    $select_pairs{$pair} = ($target_no - $sum)/2; 
    printf "\t $letter1   %5d   %8.3f  %8.3f\n",  $pair_ctr{$pair}, 
    2*$pair_ctr{$pair}*$fraction, $target_no - $sum;
	
    $sum += 2*$select_pairs{$pair};

    printf "\t sum:  %8.3f\n\n", $sum;

}

# check: do we have te same number of all letter's now across
# all the pairs
# initialize $letter counts
for $letter_ctr1 ( 0 .. $#letter_sorted) {
    $letter1 = $letter_sorted[$letter_ctr1];
    for $letter_ctr2 (0 ..  $letter_ctr1-1) {
	$letter2 = $letter_sorted[$letter_ctr2];
	$pair = $letter1." ".$letter2;
	$select_pairs{$pair} = $select_pairs{  $letter2." ".$letter1 };
    }
}

foreach $letter1 ( @letters ) {
    $letter_ctr{$letter1} = 0;
}

for $letter_ctr1 ( 0 .. $#letters) {
    $letter1 = $letters[$letter_ctr1];
    for $letter_ctr2 ( $letter_ctr1 .. $#letters) {
	$letter2 = $letters[$letter_ctr2];
	$pair = $letter1." ".$letter2;
	$letter_ctr{$letter1} +=  $select_pairs{$pair};
	$letter_ctr{$letter2} +=  $select_pairs{$pair};
    }
}

foreach $letter1 ( @letter_sorted ) {
    print "**  $letter1      $letter_ctr{$letter1}\n";
}
print "\n\n";

%prob = ();
for $letter_ctr1 ( 0 .. $#letters) {
    $letter1 = $letters[$letter_ctr1];
    $sum = 0;
    for $letter_ctr2 ( 0 .. $#letters) {
	$letter2 = $letters[$letter_ctr2];
	#next if ( $letter1 eq $letter2 );
	$pair = $letter1." ".$letter2;
	if ( ! defined  $select_pairs {$letter2." ".$letter1} ) {
	    die "blah\n";
	}
	$prob{$pair} = $select_pairs {$letter2." ".$letter1}/$target_no;
	if ( $letter1 eq $letter2 ) {
	    $prob{$pair} *= 2;
	}
	$sum += $prob{$pair};
    }
} 

## check:
for $letter_ctr1 ( 0 .. $#letters) {
    $letter1 = $letters[$letter_ctr1];
    $sum = 0;
    for $letter_ctr2 ( 0 .. $#letters) {
	$letter2 = $letters[$letter_ctr2];
	$sum += $prob {$letter1." ".$letter2};
    }
    print "  $letter1     $sum  \n";
    
}

#####################################################
# letter output
print "   ";
$upper = $#letters;
$lower = 0;
#$upper = 10;
#$lower = 30;

for $letter_ctr2 ( $lower .. $upper) {
    $letter2 = $letters[$letter_ctr2];
    printf  "%8s",   $letter2;
}
print "\n";
for $letter_ctr1 ( $lower .. $upper) {
    $letter1 = $letters[$letter_ctr1];
    print " $letter1 ";
    for $letter_ctr2 ($lower .. $upper) {
	$letter2 = $letters[$letter_ctr2];
	printf  "%8.3f",   $prob{$letter1." ".$letter2};
    }
    print "\n";
}
    



#####################################################
#####################################################
sub  HashByValue {
    $letter_ctr{$a} <=> $letter_ctr{$b};
}


#####################################################
#####################################################
sub  HashByValue2 {
    $remainder{$a} <=> $remainder{$b};
}


