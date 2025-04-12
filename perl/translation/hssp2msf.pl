#! /usr/bin/perl -w
use Getopt::Std;
# FH -> autoflush(1);


getopts ('c:l:i:p:');



defined ( $opt_i) ||   
    die "Usage: hssp2msf -i <hssp_file> [-c <chain_label>] [-l <required_length>] [-p <pdb_file>].\n";
open (HSSP, "<$opt_i") ||  die "Cno $opt_i: $!.\n";


$required_frac = 0;
$pdbfile = "";
( defined  $opt_c) && ( $user_first_chain = $opt_c);
( defined $user_first_chain ) && ($first_chain_label = $user_first_chain);
( defined  $opt_l) && ( $required_frac  =  $opt_l);
( defined  $opt_p) && ( $pdbfile = $opt_p);

$i = 0;
$read_open = 0;
$name_read_open = 0;
$seq[0] = "";

$seqlen = 0;
$max_position = 0;
$position = 0;
$first_round = 1;
while ( <HSSP> ) {
    if ( /^PDBID/ ) {
	@aux = split;
	$names[0] = $aux[1];
    }elsif ( /^SEQLENGTH/ ) {
	@aux = split;
	$seqlen = $aux[1];
	$emptyseq = "";
	for $i (1.. $seqlen) {
	    $emptyseq .= ".";
	}
    } elsif ( /^\#\#/ ) {
	if ( $max_position < $position) {
	    # I need it when I'm skippig one chain
	    $max_position = $position;
	}
	if ( $read_open) {
	    $read_open = 0;
	    $name_read_open = 0;
	    #print "\nfirst: $first     last: $last     max_pos = $max_pos \n"; 
	}
	if ( /ALIGNMENTS/ ) {
	    $read_open = 1;
	    $name_read_open = 0;
	    $position = 0;
	    if ( $first_round) {
		$first_round = 0;
		#initialize all seqs to gaps only
		foreach $name ( @names ) {
		    $seq{$name} = $emptyseq;
		}
	    }
	    #print;
	    chomp;
	    @aux = split;
	    $first = $aux[$#aux-2];
	    $last =  $aux[$#aux];	    
	    last if ($first == 1 && defined $seq[1]);

	} elsif (/PROTEINS/) {
	    $name_read_open = 1;
	}
    } elsif ( /^\s*(\d+)/ ) {
	$column = $1;
	if ($read_open) {
	    # 13 is the column of the query seq
	    # skip this whole row if it is an exclamation mark:
	    next if ( (substr $_, 14, 1) eq "!" );
	    if (  (substr $_, 14, 1) eq "X"  && $pdbfile) { process_X () };
	    # if the chain label has changed, close the read
	    $chain_label =  uc substr $_, 12, 1;
	    if ( defined $first_chain_label) {
		next if ( $chain_label ne  $first_chain_label);
	    } else {
		$first_chain_label = $chain_label;
	    }
	    $position++;
	    chomp;
	    @aux = split;
	    if ( (length $_) > 50 ) {
		$aux2 = substr  $_, 51 ;
	    } else {
		$aux2 = "";
	    }
	    @value = split '', $aux2;

	    while (  $#value < $last-$first) {
		push @value, ' ';
	    }
	    #print "$aux[0] values: 0 .. $#value  $aux2\n";
	    if ( $first == 1 ) {
		substr ( $seq{$names[0]}, $position-1,1 ) =  uc substr $_, 14, 1; 
	    }
	    foreach  $column ( $first .. $last) {
		$name = $column_name[$column];
		if ( $value[$column-$first] =~ /\w/ ) {
		    substr ( $seq{$name}, $position-1,1) =  uc $value[$column-$first];
		}
	    }
	    $max_seq = $last;

	} elsif  ($name_read_open) {
	    chomp;
	    $line = $_;
	    $column_name[$column] = substr $_,8,12 ;
	    $column_name[$column] =~ s/\s//g;
	    $alignment_length = substr $line, 60, 5;
	    if ( defined $names_found{$column_name[$column]} ) {
		$almt_len{$column_name[$column]} += $alignment_length ;
	    } else {
		push @names, $column_name[$column];
		$names_found{$column_name[$column]} = 1;
		$almt_len{$column_name[$column]} = $alignment_length ;
		$skip{$column_name[$column]} = 0;
	    }	    
	}
    }
}
close HSSP;


$seqlen = $max_position; # note: hssp does not report gaps in the query (restricts the alignment to query)
$almt_len{$names[0]} = $seqlen;


foreach $name ( @names) {
    #$seq{$name} =~ s/X/\./gi ;
    next if ( $name eq $names[0] );
    if ( $seq{$name} !~ /\w/ ) {
	$skip{$name} = 1; # not sure why this happens - I get all gaps for some seqs
    }
    next if ($skip{$name});
    if ( $required_frac ) {
	$almt_frac = $almt_len{$name}/$seqlen;
	if ( $almt_frac < $required_frac ) {
	    $skip{$name} = 1;
	}
   }
}

if ( defined $user_first_chain )  {
    $newname = $names[0].$user_first_chain;
    $seq{$newname} = $seq{$names[0]};
    undef $seq{$names[0]} ;
    $skip{$newname} = $skip{$names[0]};
    undef $skip{$names[0]} ;
    
    $names[0] = $newname;
}

$first = 0;
$last = $max_seq;

#########################################################################################################
# a patch, bcs the whole thing is just too messy: check one more time
# for gapped seqs 
foreach  $name ( @names) {
    next if ( $skip{$name});

    $aux_string = $seq{$name};
    $aux_string =~ s/\.//g;
    if ( length ( $aux_string)/$seqlen <  $required_frac ) {
	$skip{$name} = 1;
    } 
}

print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names) {
    next if ( $skip{$name});
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach  $name ( @names) {
	next if ( $skip{$name});
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 > $seqlen ) {
		$patch_length = $seqlen -($j+$k*10);
		printf ("%-10s ",   substr ($seq{$name}, $j+$k*10, $patch_length ));
		last;
	    } else {
		printf ("%-10s ",   substr ($seq{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}

0;

#########################################################################################################
#sub process_X () { # see if I can rcognize the  X as a modified residue
#    print `grep MODRES $pdbfile`;
#    exit;
#}
#########################################################################################################
#  sample line in hssp:
#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
#    1 : Q6S3H8_TORMA2BG9    1.00  1.00  909 1051  199  341  143    0    0  522  Q6S3H8     Acetylcholine receptor delta subunit.
