#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: remove_redundant_fasta  <name>\n";

$seq = "";
$name = "";
$query_name = $ARGV[0];

$fastafile = "$query_name.fasta";

open ( FASTA_OLD, "<$fastafile" ) ||
    die "Cno $bkp:$! .\n";

$fastanew = "$query_name.nr.fasta";
		
open ( FASTA_NEW, ">$fastanew" ) ||
    die "Cno $fastanew:$! .\n";

$seq = "";
$name = "";

TOP: while ( <FASTA_OLD> ) {

    if (/^>/ ) {
	if ( $seq ) {
	    if ( ! defined $found{$name} ) {
		$found{$name} = 1;
		print FASTA_NEW "> $name\n";
		print FASTA_NEW $seq;
	    } else {
		print "duplicate: $name\n";
	    }
	}
	$seq = "";
	chomp;
	($blah, $name) = split;
    } else {
	$seq .= $_;
    }
}

if ( $seq ) {
    if ( ! defined $found{$name} ) {
	$found{$name} = 1;
	print FASTA_NEW "> $name\n";
	print FASTA_NEW $seq;
    }else {
	print "duplicate: $name\n";
    }
}


close FASTA_OLD;
close FASTA_NEW;
