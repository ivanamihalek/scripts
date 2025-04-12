#! /usr/bin/perl 

sub formatted_sequence ( @);
# <struct msf> is an msf file obtained by structurally aligning
#   <pdb_name_1>  and  <pdb_name_2> 

( defined $ARGV[1] ) ||
    die "Usage: align_by_struct.pl  <struct_msf> <almt1>  <almt2> ....\n".
    "or: align_by_struct.pl  -f <msf list file>  \n";


$muscle   = "/home/ivanam/downloads/muscle3.6_src//muscle";
$afa2msf  = "/home/ivanam/perlscr/translation/afa2msf.pl";
$msf2afa  = "/home/ivanam/perlscr/translation/msf2afa.pl";
$restrict = "/home/ivanam/perlscr/msf_manip/restrict_msf_to_query.pl";
$remove_gaps = "/home/ivanam/perlscr/msf_manip/remove_gap_only.pl";

foreach ($muscle, $afa2msf, $restrict, $remove_gaps ) {
    (-e $_) || die "$_ not_found";
}

$structmsf = "";
@msfs = ();

if ( $ARGV[0] eq "-f" ) {

    open (IF, "<$ARGV[1]") ||
	die "Cno $ARGV[1]: $!.\n";

    $structmsf = "";
    @msfs = ();
    while ( <IF> ) {
	next if ( !/\S/);
	chomp;
	if ( ! $structmsf ) {
	    ($structmsf) = split " ";
	} else {
	    push @msfs, split " ";
	}
    }
    close IF;

} else {
    $structmsf =  shift @ARGV;
    @msfs = @ARGV;
}

print "$structmsf\n";
print "@msfs\n";


warn "Note: won't work if  there are gaps in the query in  any of @msfs.\n";

##################################################################
#  read in the alignemnt of anchors

#########

@structnames = ();
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
	push @structnames, $seq_name;
    }
}
close MSF;
$max_pos_structseq =  length ($structseq{$seq_name}) - 1;


#`rm tmp.msf`;



##################################################################
# which anchors are present in the msf files ?

#########
@anchors = ();
%anchor  = ();
foreach $msf ( @msfs ) {

    @names = split '\n', `grep Name $msf | awk \'\{print \$2\}\'`;
    # exactly one structname should be present in the $msf file
    $matches = 0;
    foreach $structname (@structnames) {
	foreach $name (@names) {
	    if ( $name eq $structname ) {
		$anchor = $structname;
		$matches ++;
		next;
	    }
	}
    }
    ( $matches ) || die "No matching protein from $structmsf found in $msf.\n";
    ( $matches > 1 ) && die "More than one  matching protein from $structmsf found in $msf.\n";
    
    warn "file $msf corresponds to $anchor.\n"; 
    push @anchors, $anchor;
    $anchor{$msf} = $anchor;
    $msf{$anchor} = $msf;
}



##################################################################
# restrict the positions in each alignment 
# to the positions in the anchor in structmsf

foreach $msf ( @msfs ) {

    
    $anchor   = $anchor{$msf};
    $sequence = $structseq{$anchor};
    $sequence =~ s/-//g;
    # align witht the anchor seq as seen in the structmsf (=blah)
    open ( TMP, ">tmp.afa") || die "Cno tmp.afa: $!\n";
    print TMP ">blah\n";
    print TMP formatted_sequence( $sequence );
    print TMP "\n";
    close TMP;

    $cmd = "$msf2afa  $msf >  tmp_big.afa";
    (system $cmd) && die "Error running $cmd\n";
    $cmd = "$muscle -profile  -in1 tmp_big.afa -in2 tmp.afa -out tmp_$anchor.afa";
    (system $cmd) && die "Error running $cmd\n";
    $cmd = "$afa2msf  tmp_$anchor.afa > tmp_$anchor.msf";
    (system $cmd) && die "Error running $cmd\n";

    # restrict to to blah
    $cmd = "$restrict tmp_$anchor.msf blah > tmp_$anchor.restr.msf";
    (system $cmd) &&  die "Error running $cmd\n";

    # read in the restricted sequences
    @{$anchored_by{$anchor}} = ();
    open ( MSF, "<tmp_$anchor.restr.msf" ) ||
	die "Cno: tmp_$anchor.restr.msf  $!\n";

    while ( <MSF>) {
	last if ( /\/\// );
    }
    while ( <MSF>) {
	next if ( ! (/\w/) );
	chomp;
	@aux = split;
	$seq_name = $aux[0];
	($seq_name eq "blah") && next;

	if ( defined $seq{$anchor}{$seq_name} ){
	    $seq{$anchor}{$seq_name} .= join ('', @aux[1 .. $#aux]);
	} else { 
	    $seq{$anchor}{$seq_name}  = join ('', @aux[1 .. $#aux]);
	    ( defined $names{$anchor}) || (@{$names{$anchor}} = ());
	    push @{$anchored_by{$anchor}}, $seq_name;

	}
	
    }
    close MSF;


    `rm tmp_big.afa tmp.afa tmp_$anchor.afa  tmp_$anchor.msf tmp_$anchor.restr.msf`;

}


##################################################################
# turn each sequence into array

foreach $anchor ( @anchors ) {


    @{$array_struct_aux{$anchor}} =  split '', $structseq{$anchor};

    $ctr = 0;
    foreach $seq_name ( @{$anchored_by{$anchor}} ) {
	$seq{$anchor}{$seq_name} =~ s/\./-/g;
	@{$array{$anchor}[$ctr]} = split '', $seq{$anchor}{$seq_name};

	$max_pos{$anchor} = ( scalar @{$array{$anchor}[$ctr]} ) - 1;    
	$max_seq{$anchor} = $ctr;

	$ctr ++;
    }

}


##################################################################
# get rid of gaps in all anchors (the structmsf file can have
# more anchors than we need)

foreach $pos ( 0 ..  $max_pos_structseq ) {
    $all_gaps[$pos] = 1;
    foreach $anchor ( @anchors ) {
	if ($array_struct_aux{$anchor}[$pos]  ne "-" ){
	    $all_gaps[$pos] = 0;
	    last;
	}
    }
}

$new_pos = -1;
foreach $pos ( 0 ..  $max_pos_structseq ) {
    next if ( $all_gaps[$pos] );
    $new_pos ++;
    foreach $anchor ( @anchors ) {
	$array_struct{$anchor}[$new_pos] = $array_struct_aux{$anchor}[$pos];
    }
}

$max_pos_structseq = $new_pos;  # max index a position can have



##################################################################
#sanity:
for $anchor ( @anchors ) {

    $length = 0;
    foreach $pos ( 0 .. $max_pos_structseq) {
	($array_struct{$anchor}[$pos]  eq  "-"  )  || ($length++);
    }
  
    if ( $length != $max_pos{$anchor}+1  )  {
	printf "structname length mismatch for $anchor\n";
	
	print " $length in $structmsf, ", $max_pos{$anchor}+1, " in $msf{$anchor} alignment.\n";
	exit;
    }
}


################################################################## 
#  insert gaps as suggested by structmsf

for $ctr ( 0 .. $#anchors ) {
    $pos[$ctr] = -1;
}

foreach $pos_in_struct_almt ( 0 .. $max_pos_structseq) { 

    $anchor_ctr = 0;
    for $anchor ( @anchors ) {


	$gap =  ( $array_struct{$anchor}[$pos_in_struct_almt]  eq  "-"  ); 

	if ( $gap ) {
	    $newchar = "-"; 
	} else {
	    $pos[$anchor_ctr]++;
	}

	foreach $seq ( 0 .. $max_seq{$anchor}) {

	    ( $gap ) ||  ($newchar = $array{$anchor}[$seq][$pos[$anchor_ctr]]); 
	    $new_array{$anchor}[$seq][$pos_in_struct_almt] = $newchar; 


	} 

	$anchor_ctr++;
   
    }

}



##################################################################
#  output in the msf format

$seqlen = $max_pos_structseq+1;
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;

foreach $anchor (@anchors) {
    foreach $seq ( 0 .. $max_seq{$anchor}) {
	$name = $anchored_by{$anchor}[$seq];
       
	printf (" Name: %-30s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
    }
}

printf "\n//\n\n\n\n";


for ($j=0; $j  < $seqlen; $j += 50) {

    foreach $anchor (@anchors) {

	foreach $seq ( 0 .. $max_seq{$anchor}) {
	    $name = $anchored_by{$anchor}[$seq];
	    printf "%-30s", $name;
	    for ( $k = 0; $k < 5; $k++ ) {
		if ( $j+$k*10+10 >= $seqlen ) {
		    $upper =  $max_pos_structseq ;
		} else {
		    $upper =  $j+$k*10 +9;
		}
		for $ctr ( $j+$k*10 .. $upper) {
		    if ( ! defined  $new_array{$anchor}[$seq][$ctr] ) {
			print "\nERROR: $anchor   $name  $ctr  $new_array{$anchor}[$seq][$ctr] \n"; exit;
		    }
		    printf ("%1s",   $new_array{$anchor}[$seq][$ctr] );
		    
		}
		printf " ";
	    }
	    printf "\n";
	} 

    }
    printf "\n";

}

#############################################################
#############################################################
#############################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 
