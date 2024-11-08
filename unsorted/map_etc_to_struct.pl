#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# starting with the mapfile pdbid--> almtid  and *ranks_sorted file  construct file to used by readranks
#  useful when the pdb is not part of the almt, or when the almt is nucleotide

( defined $ARGV[2] )  ||
    die "Usage: map_etc_to_struct.pl <'aa' or 'nt'> <map file> <ranks file>.\n";

if ( $ARGV[0] eq "aa" ) {
    $aa = 1;
} elsif ( $ARGV[0] eq "nt" ) {
    $aa = 0;
} else {
    die "Unrecognized second argument.\nUsage: map_etc_to_struct.pl <aa or nt> <map file> <ranks file> [-int].\n";
}

$mapfile   =  $ARGV[1];
$ranksfile =  $ARGV[2];

$int_trace = 0;
if ( defined  $ARGV[3]) {
    if (  $ARGV[3] eq "-int" ) {
	$int_trace = 1;
    }
}

open ( MAP, "<$mapfile" )     || die "Cno $mapfile: $!.\n";
while ( <MAP> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    $almt2pdbid{$aux[1]} = $aux[0];
}
close MAP;


open ( RANKS, "<$ranksfile" ) || die "Cno $ranksfile: $!.\n";

$ctr = 0;
if ( $aa) {

    while ( <RANKS> ) {
	next if (/^%/ );
	next if ( !/\S/ );
	chomp;
	@aux = split;
	if ( defined  $almt2pdbid{$aux[0]} ) {
	    $ctr ++;
	    if ( $int_trace ) {
		print "$ctr      $aux[3]\n";
	    } else {
		print "$ctr      $aux[$#aux-1]\n";
	    }
	}
    }

} else {
    #nucleotides: combine three bps into a codon
    undef $/;
    $_ = <RANKS>;
    $/ = "\n";
    @lines = split '\n', $_;
    for ($linectr=0; $linectr<= $#lines; $linectr ++ ) {
	next if ( $lines[$linectr] =~ /^%/ );
	next if ( $lines[$linectr] !~ /\S/ );

	$line = $lines[$linectr];
	@aux = split ' ', $line;
	$nt_ctr = $aux[0];
	if ( ! ( $nt_ctr %3 ) && defined  $almt2pdbid{$nt_ctr/3} ) {

	    $ctr ++;
	    $bp[2] = $aux[$#aux-1];

	    # the previous  two basepairs 
	    $line = $lines[$linectr-1];
	    @aux = split ' ', $line;
	    $bp[1] =  $aux[$#aux-1];


	    $line = $lines[$linectr-2];
	    @aux = split ' ', $line;
	    $bp[0] =  $aux[$#aux-1];
	    
            # cookup the score here
	    $score = $bp[0]  +  $bp[1]  + 0.1* $bp[2];
	    #print "$linectr   $ctr   $bp[0]   $bp[1]   $bp[2]  $score\n";
	    print "  $ctr     $score\n";

	}
	
	
    }

}

close RANKS;
