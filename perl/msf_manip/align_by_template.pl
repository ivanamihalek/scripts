#! /usr/bin/perl 
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# <struct msf> is an msf file obtained by structurally aligning
#   <pdb_name_1>  and  <pdb_name_2> 

( defined $ARGV[1] ) ||
    die "Usage: align_by_struct.pl  <struct_msf> <almt1>  <almt2> ....\n";


$structmsf =  shift @ARGV;
@msfs = @ARGV;
warn "Note: won't work if  there are gaps in the query in  any of @msfs.\n";

##################################################################
#  read in the  msfs

#########
@queries = ();
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
	push @queries, $seq_name;
    }
}
close MSF;



#########
@anchors = ();
foreach $msf ( @msfs ) {

    @names = split '\n', `grep Name $msf | awk \'\{print \$2\}\'`;
    # exactly one query should be present in the $msf file
    $matches = 0;
    foreach $query (@queries) {
	foreach $name (@names) {
	    if ( $name eq $query ) {
		$anchor = $query;
		$matches ++;
		next;
	    }
	}
    }
    ( $matches ) || die "No matching protein from $structmsf found in $msf.\n";
    ( $matches > 1 ) && die "More than one  matching protein from $structmsf found in $msf.\n";
    
   # printf "file $msf corresponds to $anchor.\n"; 
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
	if ( defined $seq{$anchor}{$seq_name} ){
	    $seq{$anchor}{$seq_name} .= join ('', @aux[1 .. $#aux]);
	} else { 
	    $seq{$anchor}{$seq_name}  = join ('', @aux[1 .. $#aux]);
	}
	
    }
    close MSF;
    push @anchors, $anchor;
}
#########


##################################################################
# turn all  msfs into a table (first index= sequence, 2nd index= position)

#########


for $ctr ( 0 .. $#anchors ) {
    $structseq{$anchor} =~ s/\./\-/g;
}

for $ctr ( 0 .. $#anchors ) {
    $anchor = $anchors[$ctr];
    @aux = split '', $structseq{$anchor};
    foreach $pos ( 0 .. $#aux ) {
	$array_struct_aux[$ctr][$pos] = $aux[$pos];
    }
}
$max_pos_structseq = $#aux;  # max index a position can have


# get rid of positions which are gaps in all anchors
foreach $pos ( 0 .. $max_pos_structseq ) {
    $all_gaps[$pos] = 1;
}

foreach $pos ( 0 ..  $max_pos_structseq ) {
    for $ctr ( 0 .. $#anchors ) {
	if ($array_struct_aux[$ctr][$pos]  ne "-" ){
	    $all_gaps[$pos] = 0;
	    last;
	}
    }
}

$gapped = 0;
foreach $pos ( 0 ..  $max_pos_structseq ) {
    $gapped += $all_gaps[$pos] ;
}
   
$new_pos = -1;
foreach $pos ( 0 ..  $max_pos_structseq ) {
    next if ( $all_gaps[$pos] );
    $new_pos ++;
    for $ctr ( 0 .. $#anchors ) {
	$array_struct[$ctr][$new_pos] = $array_struct_aux[$ctr][$pos];
    }
}

$max_pos_structseq = $new_pos;  # max index a position can have


 
#########



foreach $anchor ( @anchors ) {

    $ctr = 0;
    foreach $seq_name ( keys %{$seq{$anchor}} ) {

	$seq{$anchor}{$seq_name} =~ s/\./\-/g;
	@aux = split '', $seq{$anchor}{$seq_name};
	foreach $pos ( 0 .. $#aux ) {
	    $array{$anchor}[$ctr][$pos] = $aux[$pos];
	}
	$names{$anchor}[$ctr] = $seq_name;
	$ctr ++;
    }

    $max_seq{$anchor} = $ctr-1; # max index a seq can have
    $max_pos{$anchor} = $#aux; 

}

##################################################################
#  restrict each msf to its respective query

# already true for hssp alignments - leave as is for now
# restrict_to_query (); # not tested!

##################################################################
#sanity:
for $ctr ( 0 .. $#anchors ) {
    $length = 0;
    foreach $pos ( 0 .. $max_pos_structseq) {
	($array_struct[$ctr][$pos]  eq  "-"  )  || ($length++);
    }
    $anchor = @anchors[$ctr];
    if ( $length != $max_pos{$anchor}+1  )  {
	printf "query length mismatch for $anchor\n";
	
	print " $length in $structmsf, ", $max_pos{$anchor}+1, "  in $anchor alignment.\n";
	exit;
    }
}


################################################################## 
#  insert gaps as suggested by structmsf

for $ctr ( 0 .. $#anchors ) {
    $pos[$ctr] = -1;
}


foreach $pos_anchor ( 0 .. $max_pos_structseq) { 

    for $ctr ( 0 .. $#anchors ) {
	$anchor = $anchors[$ctr];
	$gap =  ( $array_struct[$ctr][$pos_anchor]  eq  "-"  ); 
	if ( $gap ) {
	    $newchar = "-"; 
	} else {
	    $pos[$ctr]++;
	}

	foreach $seq ( 0 .. $max_seq{$anchor}) {

	    ( $gap ) ||	 ($newchar = $array{$anchor}[$seq][$pos[$ctr]]); 

	    $new_array{$anchor}[$seq][$pos_anchor] = $newchar; 
	} 
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
	$name = $names{$anchor}[$seq];
	printf (" Name: %-30s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
    }
}

printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {

    foreach $anchor (@anchors) {

	foreach $seq ( 0 .. $max_seq{$anchor}) {
	    $name = $names{$anchor}[$seq];
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
