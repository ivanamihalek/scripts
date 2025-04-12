#! /usr/bin/perl -w 

defined $ARGV[0] || 
    die "usage: divide_fasta.pl  <name>\n";

$NO_CHUNKS = 10; # divide fasta inot this many chunks


$seq = "";
$name = "";
$query_name = $ARGV[0];

$fastafile = "3dhe.fasta";

open ( FASTA_OLD, "<$fastafile" ) || 
	die "Cno $newname:$! .\n";

$avg_len  = 0;
$avg_sq   = 0;
$no_seqs   = 0;

$ctr = 0;
TOP: while ( <FASTA_OLD> ) {
    chomp;
    next if ( !/\S/);
    if (/^>/ ) {
	$seqs[$ctr] = $seq;
	$names[$ctr] = $name;
	$ctr ++;
	$seq = "";
	$_ =~ s/\-//g;
	/^>\s*(.*)/; 
	$name = $1;
       
	print "  name: $name \n"; 

    } else {
	$seq .= $_;
    }
}
$seqs[$ctr] = $seq;
$names[$ctr] = $name;
$no_seqs = $ctr;

close FASTA_OLD;

$ctr = 0;
if ( $no_seqs % $NO_CHUNKS ) {
    $upper =  $NO_CHUNKS;
} else {
    $upper = $NO_CHUNKS+1;
}
for $div ( 1 .. $upper ) {	

    $newname = $query_name.".$div.fasta";
    open ( FASTA_NEW, ">$newname" ) || 
	die "Cno $newname:$! .\n";

    while ( $ctr < $no_seqs/$NO_CHUNKS*$div && $ctr < $no_seqs) {
	
	print FASTA_NEW  "> $names[$ctr] \n";
	@aux = split ('', $seqs[$ctr]);
	for $charctr ( 1 .. $#aux+1) {
	    print FASTA_NEW  $aux[$charctr-1];
	    if ( ! ($charctr % 50) ) {
		print FASTA_NEW  "\n";
	    }
	}
	$charctr = $#aux+1;
	if ($charctr % 100 ) {
	    print  FASTA_NEW "\n";
	}
	$ctr++;
    }
    
    close FASTA_NEW;
}


