#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);


defined $ARGV[1]  ||
    die "Usage: cleanup_msf.pl <msffile> <query_name> [<cutoff fractn>  <id near> <id far>]\n"; 


$home = `pwd`;
chomp $home;
$name  = $ARGV[0] ;
$query = $ARGV[1] ;

$CUTOFF_FRACTION = 0.75;
$CUTOFF_ID_NEAR = 0.99;
$CUTOFF_ID_FAR   = 0.4;
if ( defined $ARGV[4] ) {
    $CUTOFF_FRACTION =  $ARGV[2];
    $CUTOFF_ID_NEAR =  $ARGV[3];
    $CUTOFF_ID_FAR   =  $ARGV[4];
}

open ( MSF, "<$name" ) ||
    die "Cno: $name  $!\n";
	

while ( <MSF>) {
    if ( /^ Name/ ) {
	@aux = split;
	$seq_name = $aux[1];
	push @names,$seq_name;
    }
    last if ( /\/\// );
    last if ( /CLUSTAL FORMAT for T-COFFEE/ );
}

while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $sequence{$seq_name} ){
	$sequence{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$sequence{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;
defined  $sequence{$query} ||
    die " Sequence  $query  not found in $name.\n";
 
open ( LOG, ">$name.cleanup_log" ) ||
    die "Cno: $name.cleanup_log  $!\n";

print LOG join " ",  @ARGV, "\n";
# find seqs shorter than query  
$aux_string = $sequence{$query};
$aux_string =~ s/\.//g;
$query_length = length $aux_string;

foreach $seq_name ( @names ) {
    $aux_string = $sequence{$seq_name};
    $aux_string =~ s/\.//g;
    if ( length ( $aux_string) < $CUTOFF_FRACTION*$query_length ) {
	$skip{$seq_name} = 1;
	print LOG  "removing $seq_name from the alignment: shorter than  $CUTOFF_FRACTION of the query length.\n"; 
    } else {
	$skip{$seq_name} = 0; 
    } 
}
$seqlen = length $sequence{$query};  

# find seqs too far from  query  
@aux1 = split '', $sequence{$query};
foreach $ctr2 ( 0 ..  $#names  ) {
    $name2 = $names[$ctr2];
    next if ($skip{$name2} );
    next if ($name2 eq  $query);
    @aux2 = split '', $sequence{$name2};

    $non_gap_length = 0;
    $matching_length = 0;
    for $i ( 0..$seqlen-1 ) {
	next if ( $aux1[$i] eq "."  &&  $aux2[$i] eq ".");
	$non_gap_length ++;
	( $aux1[$i] eq  $aux2[$i] ) && ( $matching_length ++);
    }
    $non_gap_length || next;
    if ( $matching_length/$non_gap_length <  $CUTOFF_ID_FAR ) {
	$skip{$name2} = 1;  
	print LOG  "removing $name2 from the alignment: less than   $CUTOFF_ID_FAR from the query.\n"; 
    }

}


# find  sequences which are too similar
# first count gaps
foreach $name ( @names  ) {
    next if ($skip{$name} );
    $aux_string = $sequence{$name};
    $ret = ( $aux_string =~ s/\.//g );
    (defined $ret)  &&  ($ret =~ /\S/) || ($ret = 0);
    $no_gaps{$name} = $ret;
}

# close pairs
foreach $ctr1 ( 0 ..  $#names-1  ) {
    $name1 = $names[$ctr1];
    next if ($skip{$name1} );
    @aux1 = split '', $sequence{$name1};
    foreach $ctr2 ( $ctr1+1 ..  $#names  ) {
	$name2 = $names[$ctr2];
	next if ($skip{$name2} );
	@aux2 = split '', $sequence{$name2};

	$non_gap_length = 0;
	$matching_length = 0;
	for $i ( 0..$seqlen-1 ) {
	    next if ( $aux1[$i] eq "."  &&  $aux2[$i] eq ".");
	    $non_gap_length ++;
	    ( $aux1[$i] eq  $aux2[$i] ) && ( $matching_length ++);
	}
	$non_gap_length || next;
	if ( $matching_length/$non_gap_length >= $CUTOFF_ID_NEAR ) {
	    if ( $name1 =~ $query ) {
		$skip{$name2} = 1;  
		print LOG  "removing $name2 from the alignment: more than than   $CUTOFF_ID_NEAR of  the query.\n"; 
	    } elsif ( $name2 =~ $query ){
		$skip{$name1} = 1;  
		print LOG  "removing $name1 from the alignment: more than than   $CUTOFF_ID_NEAR of  the query.\n"; 
	    } elsif ($no_gaps{$name1} > $no_gaps{$name2}) {
		$skip{$name1} = 1;  
		print LOG  "removing $name1 from the alignment: more than than   $CUTOFF_ID_NEAR of  the $name2.\n"; 
	    } else {
		$skip{$name2} = 1;  
		print LOG  "removing $name2 from the alignment: more than than   $CUTOFF_ID_NEAR of  the $name1\n"; 
	    }
	}

    }
}

close LOG;

print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names  ) {
    next if ($skip{$name} );
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name ( @names  ) {
	next if ($skip{$name} );
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
