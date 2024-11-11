#! /usr/gnu/bin/perl -w
#VERSION  07/15/02

#   random_tyrosins.pl random_human_proteins > ! t1.dat

defined ( $ARGV[0] ) ||
    die "usage: find_seq_motifs.pl <fasta file>.\n";


open ( INFILE, "<$ARGV[0]")  ||  die "cannot open $ARGV[0] file\n" ;


$sequence = "";
$total = 0;
$seq_count = 0;
$no_hits = 0;
# read in the sequence and get rid of the whitespaces
while (<INFILE> )  {
    next if ( ! /\S/ ) ;
    chomp;

    if(/>/) {
	if ( $sequence ) {
	    if ( rand() < 0.05 ) {
		$seq_count ++;
		$sequence =~ s/\s//g;
		$sequence = uc $sequence;
		$match = ( $sequence =~ s/[LV][DEKA].LL/xxxxx/g );
		if ( $match  ) {
		    $total += $match;
		    $no_hits ++;
		}
		last if ( $seq_count >= 500000 );
 	    }
	}
	$sequence = "";
    } else {
	$sequence .= $_;
	
    }
}

printf " no_seqs: $seq_count   hits:  $no_hits    total match: $total \n";
