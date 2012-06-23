#! /usr/bin/perl -w



while ( <> ) {
   
    $begin = time;
    chomp;
    @aux = split;
    $name = $aux[0];
    

    $list{$name} =`extr_names_from_msf.pl  < $name`;
    
}


foreach $name1 ( keys %list ) {
    print "\n\n\n$name1:\n";
    @seqs = split  "\n", $list{$name1};
    foreach $seq ( @seqs ) {
	print "\t$seq\n";
	foreach $name2 ( keys %list ) {
	    next if ($name1 =~ $name2 && $name2 =~ $name1);
	    if ( $list{$name2} =~ $seq ) {
		print "  $seq present in $name1 and $name2 \n";
	    }
	}
    }
}
