#! /usr/bin/perl -w

defined $ARGV[1] || 
    die "usage: remove_matching  <fasta file> <query name>\n";

$seq = "";
$name = "";
$query_name = $ARGV[1];
$query_name =~ s/\s//g;

$fastafile = $ARGV[0];

open ( FASTA_OLD, "<$fastafile" ) ||
    die "Cno $fastafile:$! .\n";

open ( LOG, ">$query_name.frag.log" ) ||
    die "Could not open $name.pruning.log:  $!\n";
	
$protected = ""; 

# find query
while ( <FASTA_OLD> ) {
    next if ( !/\S/);
    if (/^>\s*(\w*)/ ) {
	last if ( defined  $query_seq);
	$tmp = $1;
	if ( $tmp =~  $query_name && $query_name =~ $tmp) {
	    $query_seq = "";
	}
    } else {
	if ( defined $query_seq) {
	    chomp;
	    $query_seq .= $_;
	}
    }
}

$qlen = length $query_seq;
seek FASTA_OLD, 0, 0;

TOP: while ( <FASTA_OLD> ) {
    chomp;

    if (/^>/ ) {
	if ( $seq ) {
	    if ( $seq =~ /X/i ) {
		print LOG "Removing $name: contains X.\n"; 
	    } elsif (  ($name =~ $query_name && $query_name =~ $name ) || ! defined %list ) {
		$list{$name} = $seq;
	    } else  { 
		printf "$name   %10.4f \n", (length $seq)/$qlen;
		if ( (length $seq) > 0.75*$qlen)  { 
		    $list{$name} = $seq; 
		} else {
		    printf LOG "$name too short:  %10.4f \n", (length $seq)/$qlen;
		}
	    }

	}
	$seq = "";
	/^>\s*([\w\d\-\_]+)\s*/;
	$name = $1;

    } else {
	$seq .= $_;
    }
}

close FASTA_OLD;

if ( $seq ) {
	    if (  defined %list ) {
		$found_already = 0;
		foreach $prev ( keys %list) {
		    if ( $seq =~ $list{$prev} || $list{$prev} =~  $seq) {
			$found_already = 1;
			last;
		    }
		}
		if ( ! $found_already)  {
		    $list{$name} = $seq;
		}
	    } else {
		$list{$name} = $seq;
	    }
}

		
open ( FASTA_NEW, ">$fastafile.no_frag" ) ||
    die "Cno $fastafile.no_frag:$! .\n";


foreach $name ( keys %list) {
    print FASTA_NEW  "> $name \n";
    @aux = split ('', $list{$name});
    for $ctr ( 1 .. $#aux+1) {
	print FASTA_NEW  $aux[$ctr-1];
	if ( ! ($ctr % 50) ) {
	    print FASTA_NEW  "\n";
	}
    }
    $ctr = $#aux+1;
    if ($ctr % 100 ) {
	  print  FASTA_NEW "\n";
    }
    
}

