#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# <struct msf> is an msf file obtained by structurally aligning
#   <pdb_name_1>  and  <pdb_name_2> 
# similar to align_by_struct - but aligns single msf with structural

defined ( $ARGV[1] ) ||
    die "Usage: align_by_struct.pl   <pdb_name >   <struct_msf>.\n";

printf "Note: won't work if  there are gaps in the query in the msf.\n";

$query     =  $ARGV[0];
$msf       = "$query.msf";
$structmsf =  $ARGV[1];

##################################################################
#  read in the two msfs

open ( MSF, "<$msf" ) ||
    die "Cno: $msf  $!\n";
while ( <MSF>) {
    last if ( /\/\// );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $seq{$seq_name} ){
	$seq{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seq{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}
close MSF;
if( defined $seq{$query} ) {
    $max_pos = (length $seq{$query}) - 1  ;
} else {
    die "$query not found in $msf.\n"; 
}



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

if  ( defined $structseq{$query} ) {
    $max_pos_structseq = (length $seq{$query}) - 1  ;
} else {
    die "$query not found in $structmsf.\n"; 
}


close MSF;


##################################################################
# turn   msfs into a table (first index= sequence, 2nd index= position)
$seq = 0;
@name = ();
foreach $seq_name ( keys %seq ) {
    $seq{$seq_name} =~ s/\-/\./g;
    @aux = split '', $seq{$seq_name};
    ($#aux  == $max_pos) || die "Error.\n";
    foreach $pos ( 0 .. $max_pos ) {
	$array[$seq][$pos] = $aux[$pos];
    }
    $names[$seq] = $seq_name;
    $seq++;
}
$max_seq = $seq-1; # max index a seq can have


$seq = 0;
foreach $seq_name ( keys %structseq ) {
    $structseq{$seq_name} =~ s/\-/\./g;
    if ( $seq_name eq $query ) {
        $queryctr = $seq;
    } 
    @aux = split '', $structseq{$seq_name};
    foreach $pos ( 0 .. $#aux ) {
        $array_struct[$seq][$pos] = $aux[$pos];
    }
    $seq++;
}

#  $max_structseq = $seq-1; # max index a seq can have

=pod
foreach   $seq_name ( keys %structseq ) {
    print " $seq_name \n";
}
print "query:  $queryctr\n";
=cut

##################################################################
#  restrict each msf to its respective query

# already true for hssp alignments - leave as is for now

##################################################################
=pod
foreach $pos ( 0 .. $max_pos) {
    foreach $seq ( 0 .. $max_seq) {
	    print " $array[$seq][$pos]";
    }
    print "\n";
}
exit;
=cut

##################################################################
#  insert gaps as suggested by structmsf

$pos = -1; 


foreach $struct_pos ( 0 .. $max_pos_structseq) {

    $gap = 0;
    ( $array_struct[$queryctr][$struct_pos]  eq  "."  )  &&   ($gap = 1);
    $gap || ($pos++);
    foreach $seq ( 0 .. $max_seq) {

	if ( $gap ) {
	    $newchar = ".";
	} else {
	    $newchar = $array[$seq][$pos];
	}
	$new_array[$seq][$struct_pos] = $newchar;
    }
}

# tack the remaining seqs from the structurarl alignmetn to the end here
$seq = $max_seq + 1;
foreach $seq_name ( keys %structseq ) {
    next if ( $seq_name eq $query );
    print "$seq_name \n";
    push @names, $seq_name;
    @aux = split '', $structseq{$seq_name};
    foreach $pos ( 0 .. $#aux ) {
        $new_array[$seq][$pos] = $aux[$pos];
    }
    $seq++;
}
$max_seq = $seq - 1;;


##################################################################
#  output in the msf format

$seqlen = $max_pos_structseq+1;
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {

    foreach $seq ( 0 .. $max_seq) {
	$name = $names[$seq];
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
	        $upper =  $max_pos_structseq ;
	    } else {
		$upper =  $j+$k*10 +9;
	    }
	    for $ctr ( $j+$k*10 .. $upper) {
		if ( ! defined  $new_array[$seq][$ctr] ) {
		    print "Error: seq  $seq    ctr $ctr \n"; exit;
		}
		printf ("%1s",   $new_array[$seq][$ctr] );
	    }
	    printf " ";
	}
	printf "\n"; 
    } 
    printf "\n";
}



