#! /usr/bin/perl -w 

defined $ARGV[0] || 
    die "usage: remove_matching  <name>  [<protected>]\n";
sub process_seq ();

$seq = "";
$name = "";
$protected = "";

$fastafile = $ARGV[0];
(defined  $ARGV[1])  && ($protected  = $ARGV[1]);
$bkp = "$fastafile.bkp";

rename $fastafile, $bkp;
open ( FASTA_OLD, "<$bkp" ) ||
    die "Cno $bkp:$! .\n";

$avg_len  = 0;
$avg_sq   = 0;
$no_seqs   = 0;

TOP: while ( <FASTA_OLD> ) {
    chomp;
    next if ( !/\S/);
    if (/^>/ ) {
	process_seq();
	$seq = "";
	$_ =~ s/\-//g;
	/^>\s*(.*)/; 
	$name = $1;
	$name =~ s/\s//g;
	#print "  name: $name \n"; 

    } else {
	$seq .= $_;
    }
}
close FASTA_OLD;

process_seq();
$avg_len /= $no_seqs;
$avg_sq /= $no_seqs;
$stdev = sqrt ($avg_sq - $avg_len*$avg_len);
print " avg = $avg_len   stdev = $stdev \n"; 



		
open ( FASTA_NEW, ">$fastafile" ) ||
    die "Cno $fastafile:$! .\n";

( $protected) && ( $query_length = length $list{$protected} );

foreach $name ( keys %list) {
    $len = length $list{$name};
    if ( $name ne  $protected  ){
	#if ( $protected &&  ($query_length - $len) > 50 ) {
	#    print " dropping $name: length = $len, query length = $query_length\n"; 
	#    next;
	#} #elsif ( $protected &&  ($query_length - $len) < -200 ) {
	    #print " dropping $name: length = $len, query length = $query_length\n"; 
	    #next;
	#}
	if ( ($len-$avg_len)/$stdev < -1 ) {
	    print " dropping $name: length = $len, avg = $avg_len \n"; 
	    next;
	} elsif  ( ($len-$avg_len)/$stdev > 1 ) {
	    print " dropping $name: length = $len, avg = $avg_len \n"; 
	    next;
	} 
    } 
    if ( defined $found{$name} ) {
	print "dropping $name: found already.\n";
	next;
    } else {
	$found{$name} = 1;	
    }
    print FASTA_NEW  ">$name \n";
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

exit  0;

#########################################################################
sub process_seq () {
	if ( $seq ) {
	    #print "$name \n";
	    if ( $name =~ /hypothetical/i || $name =~ /putative/i || $name =~ /oxidase/i || $name =~ /hydrogenase/i 
                  || $name =~ /unknown/i   || $name =~ /mutant/i || $name =~ /mutation/i 
		|| $name =~ /reductase/i  || $name =~ /similar/i || $name =~ /probable/i ) {
		print "\tdropping $name.\n";
	    }  else  {
		$len = length $seq;
		$list{$name} = $seq;
                $avg_len    +=  $len;
                $avg_sq     +=  $len*$len;
		$no_seqs ++;
	    }

	}
}
