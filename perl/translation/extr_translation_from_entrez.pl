#! /usr/gnu/bin/perl -w 
# 1) start with a list of gi's (produced by retrieve.pl)
# 2) do batch download of protein entries from Entrez
# 3) pipe it all as one file through this
# 4) this will produce a table in the form 
#        [gi]  [tax name (shortened)]  [single string descriptor]
#    descriptor length is set in the variable $DESCR_LENGTH below
#    the table is piped directly to stdout
# 5) use that table as an input to gi2name.pl
$DESCR_LENGTH = 50;
$name = "";
$descr = "";
$locus = "";
$gi = 0;


%seqs = ();

TOP: while ( <> ) {

    if ( /LOCUS/ ) {
    } elsif ( /ORGANISM/ ) {
    } elsif (/VERSION/) {
	chomp;
	@aux = split ':';
	$gi = $aux[1];
	
    } elsif (/FEATURES/){
	while ( <> ) {
	    redo TOP  if (/ORIGIN/ || /BASE COUNT/);
	    $keyword = substr $_, 0, 20;
	    if ( $keyword =~ /CDS/ ){
		$ctr ++;
		#chomp;
		#print " $ctr: $_";
		$cds = 1;
	    } elsif ( $keyword =~ /\S/ ) {
		$cds = 0;
	    }
	    if ( $cds ) {
		if ( !$gene && (/gene/ || /note/) && /\"(.+)[\"\n]/ ) {
		    $gene = $1;
		} elsif ( /translation/ ) {
		    chomp;
		    $_ =~ /\"(.+)/;
		    
		    $seqs{$gi} = $1;
		    while ( <> ) {
			$seqs{$gi} .= $_;
			if ( /\"/ ) {
			    $seqs{$gi} =~ s/\"//;
			    $seqs{$gi} =~ s/\n//g;
			    $seqs{$gi} =~ s/\s//g;
			    #print "$gi\n";
			    #print "$seq{$gi}\n";
			    last;
			}
		    }
		}
	    }
	}
    } elsif (/BASE_COUNT/){
    } elsif (/ORIGIN/){
    }
    
}

foreach $seq_name ( keys %seqs ) {
	
    @seq = split ('', $seqs{$seq_name});
    print  ">$seq_name \n";
    $ctr = 0;
    for $i ( 0 .. $#seq ) {
	if ( $seq[$i] !~ '\.' ) {
	    ( $seq[$i] =~ '\-' ) && ( $seq[$i] = '.' );
	    print   $seq[$i];
	    $ctr++;
	    if ( ! ($ctr % 50) ) {
		print  "\n";
	    }

	}
    }
    print  "\n";
}

