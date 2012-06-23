#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: remove_matching  <name>\n";

$seq = "";
$name = "";
$query_name = $ARGV[0];

$fastafile = "$query_name.fasta";
$bkp = "$fastafile.bkp";

rename $fastafile, $bkp;
open ( FASTA_OLD, "<$bkp" ) ||
    die "Cno $bkp:$! .\n";

open ( LOG, ">$query_name.pruning.log" ) ||
    die "Could not open $name.pruning.log:  $!\n";
	
$protected = ""; 

TOP: while ( <FASTA_OLD> ) {
    chomp;

    if (/^>/ ) {
	if ( $seq ) {
	    $seq =~ s/ //g;
	    if ( $seq =~ /X/i ) {
		print LOG "Removing $name: contains X.\n"; 
	    } elsif (  ($name =~ $query_name && $query_name =~ $name ) || ! defined %list ) {
		$list{$name} = $seq;
	    } else  { 
		$found_already = 0;   
		foreach $prev ( keys %list) { 
		    if ($prev =~ $name && $name =~ $prev){
			print LOG "$query_name found twice.\n"; 
			next; 
		    } 
		    
		    if (  ( $list{$prev} =~  $seq && $protected !~ $seq) || 
			( $seq  =~  $list{$prev} && $protected =~ $prev ) ) { 
			# $seq is a substring of prev 
			# or prev is substring of seq but prev is protected
			$found_already = 1; 
			print LOG "$name is a substring of $prev.\n"; 
			last; 
		    } elsif ( ( $list{$prev} =~  $seq && $protected =~ $seq) ||
			  ( $seq  =~  $list{$prev} && $protected !~ $prev )   ) { #prev is a substring of $seq
			delete $list{$prev}; 
			print LOG "$prev is a substring of $name.\n"; 
		    }
		}
		if ( ! $found_already)  { 
		    $list{$name} = $seq; 
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

		
open ( FASTA_NEW, ">$fastafile" ) ||
    die "Cno $fastafile:$! .\n";


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

