#! /usr/bin/perl 
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# <struct msf> is an msf file obtained by structurally aligning
#   <pdb_name_1>  and  <pdb_name_2> 

( defined $ARGV[4] ) ||
    die "Usage: align_by_struct.pl   <query1>  <almt1>   <query2>  <almt2>    <struct_msf>.\n";

warn "Note: won't work if  there are gaps in the query in msf1 or msf2.\n";

$query1    =  $ARGV[0];
$msf1      =  $ARGV[1];
$query2    =  $ARGV[2];
$msf2      =  $ARGV[3];
$structmsf =  $ARGV[4];

##################################################################
#  read in the three msfs

open ( MSF, "<$msf1" ) ||
    die "Cno: $msf1  $!\n";
while ( <MSF>) {
    last if ( /\/\// );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $seq1{$seq_name} ){
	$seq1{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seq1{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}
close MSF;
( defined $seq1{$query1} ) ||
    die "$query1 not found in $msf1.\n"; 
$names1 = join "_", keys %seq1;

#########

open ( MSF, "<$msf2" ) ||
    die "Cno: $msf2  $!\n";
while ( <MSF>) {
    last if ( /\/\// );
}
while ( <MSF>) { 
    next if ( ! (/\w/) );
    chomp;
    @aux = split; 
    $seq_name = $aux[0];
    next if ( $names1 =~ $seq_name );
    if ( defined $seq2{$seq_name} ){
	$seq2{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seq2{$seq_name}  = join ('', @aux[1 .. $#aux]);
    } 
} 
close MSF;
( defined $seq2{$query2} ) ||
    die "$query2 not found in $msf2.\n"; 


#########


open ( MSF, "<$structmsf" ) ||
    die "Cno: $structmsf  $!\n";
while ( <MSF>) {
    last if ( /\/\// );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $structseq{$seq_name} ){
	$structseq{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$structseq{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

( defined $structseq{$query1} ) ||
    die "$query1 not found in $structmsf.\n"; 
( defined $structseq{$query2} ) ||
    die "$query2 not found in $structmsf.\n"; 

close MSF;


##################################################################
# turn all  msfs into a table (first index= sequence, 2nd index= position)
$seq = 0;
@names1 = ();
foreach $seq_name ( keys %seq1 ) {
    $seq1{$seq_name} =~ s/\-/\./g;
    @aux = split '', $seq1{$seq_name};
    foreach $pos ( 0 .. $#aux ) {
	$array1[$seq][$pos] = $aux[$pos];
    }
    $names1[$seq] = $seq_name;
    $seq++;
}

$max_seq1 = $seq-1; # max index a seq can have
$max_pos1 = $#aux; 

$seq = 0;
@names2 = ();
foreach $seq_name ( keys %seq2 ) {
    $seq2{$seq_name} =~ s/\-/\./g;

    @aux = split '', $seq2{$seq_name};
    foreach $pos ( 0 .. $#aux ) {
	$array2[$seq][$pos] = $aux[$pos];
    }
    $names2[$seq] = $seq_name;
    $seq++;
}

$max_seq2 = $seq-1; # max index a seq can have
$max_pos2 = $#aux; 


$seq = 0;
foreach $seq_name ( keys %structseq ) {
    $structseq{$seq_name} =~ s/\-/\./g;
    if ( $seq_name eq $query1 ) {
	$queryctr1 = $seq;
    } elsif ( $seq_name eq $query2) {
	$queryctr2 = $seq;
    }
    @aux = split '', $structseq{$seq_name};
    foreach $pos ( 0 .. $#aux ) {
	$array_struct[$seq][$pos] = $aux[$pos];
    }
    $seq++;
}

$max_pos_structseq = $#aux;  # max index a position can have

##################################################################
#  restrict each msf to its respective query

# already true for hssp alignments - leave as is for now
# restrict_to_query (); # not tested!

##################################################################
#sanity:
$queryctr = $queryctr1;
$ctr = 0;
foreach $pos ( 0 .. $max_pos_structseq) {
    ($array_struct[$queryctr][$pos]  eq  "."  )  || ($ctr++);
}
if ( $ctr != $max_pos1+1  )  {
    printf "query length mismatch for $names1[$queryctr]\n";
    printf " $ctr in $structmsf, $max_pos1 in $msf1.\n";
    exit;
}

$queryctr = $queryctr2;
$ctr = 0;
foreach $pos ( 0 .. $max_pos_structseq) {
    ($array_struct[$queryctr][$pos]  eq  "."  )  || ($ctr++);
}
if ( $ctr != $max_pos2+1 ) {
    printf "query length mismatch for $names2[$queryctr2]\n";
    printf " $ctr in $structmsf, $max_pos2 in $msf2.\n";
    exit;
}


##################################################################
#  insert gaps as suggested by structmsf

$pos1 = -1; 
$pos2 = -1; 


foreach $pos ( 0 .. $max_pos_structseq) {

    $queryctr =$queryctr1;
    $gap = 0;
    ( $array_struct[$queryctr][$pos]  eq  "."  )  &&   ($gap = 1);
    $gap || ($pos1++);
    foreach $seq ( 0 .. $max_seq1) {

	if ( $gap ) {
	    $newchar = ".";
	} else {
	    $newchar = $array1[$seq][$pos1];
	}
	$new_array_1[$seq][$pos] = $newchar;
    }
    $queryctr=$queryctr2;
    $gap = 0;
    ( $array_struct[$queryctr][$pos]  eq  "."  )  &&   ($gap = 1);
    $gap || ($pos2++);
    foreach $seq ( 0 .. $max_seq2) {

	if ( $gap ) {
	    $newchar = ".";
	} else {
	    $newchar = $array2[$seq][$pos2];
	}
	$new_array_2[$seq][$pos] = $newchar;
    }
}


##################################################################
#  output in the msf format

$seqlen = $max_pos_structseq+1;
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names1  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
foreach $name ( @names2  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {

    foreach $seq ( 0 .. $max_seq1) {
	$name = $names1[$seq];
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
	        $upper =  $max_pos_structseq ;
	    } else {
		$upper =  $j+$k*10 +9;
	    }
	    for $ctr ( $j+$k*10 .. $upper) {
		if ( ! defined  $new_array_1[$seq][$ctr] ) {
		    print "\nERROR: $seq  $ctr \n"; exit;
		}
		printf ("%1s",   $new_array_1[$seq][$ctr] );
	    }
	    printf " ";
	}
	printf "\n";
    } 
    foreach $seq ( 0 .. $max_seq2) {
	$name = $names2[$seq];
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
	        $upper =  $max_pos_structseq ;
	    } else {
		$upper =  $j+$k*10 +9;
	    }
	    for $ctr ( $j+$k*10 .. $upper) {
		printf ("%1s",   $new_array_2[$seq][$ctr] );
	    }
	    printf " ";
	}
	printf "\n";
    } 
    printf "\n";


}


=pod
#################################################################################
#################################################################################
#################################################################################
#################################################################################

sub restrict_to_query () {

    # turn the msf into a table (first index= sequence, 2bd index= position
    $seq = 0;
    @name = ();
    foreach $seq_name ( keys %sequence ) {
	@aux = split '', $sequence{$seq_name};
	foreach $pos ( 0 .. $#aux ) {
	    $array[$seq][$pos] = $aux[$pos];
	}
	$names[$seq] = $seq_name;
	if (  $query eq  $seq_name) {
	    $query_ctr = $seq;
	}
	$seq++;
    }

    $max_seq = $seq-1; # max index a seq can have
    $max_pos = $#aux;  # max index a position can have


    # get rid of all positions which are "." in query
    for ($pos=$max_pos; $pos >=0; $pos--) {

	next if ( $array[$query_ctr][$pos] ne "."  );
	foreach $seq_name ( @names  ) {
	    $sequence{$seq_name} = substr ($sequence{$seq_name},0, $pos).substr ($sequence{$seq_name},$pos+1);
	}
    }

}
=cut
