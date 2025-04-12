#! /usr/gnu/bin/perl -w


(defined $ARGV[0]   ) ||
    die "usage: hack22.pl  <pdb_list>  \n.";

$pdblist = $ARGV[0];
$contfile = "contact_order";

open ( CONTFILE, "$contfile") || 
   die " could not open $contfile.\n";
while ( <CONTFILE> ) {
    last if (/min/);
    if (/pdb/) {
	@aux = split '\/';
	$name = $aux[0];
	$line = <CONTFILE>;
	chomp $line;
	@aux = split '=', $line;
	$noc{$name} =  $aux[1];
    }
}
close CONTFILE;


open (FAILFILE,">fail\n") ||
    die "cno fail file: $! \n";

open (PDBLIST, "<$pdblist") ||
    die "could not open $pdblist.\n";
while (<PDBLIST>) {

    $no_files++;
    chomp;
    $name = $_;
    $sumfile = "$name/"."$name.psi.2.cluster_report.summary";
    if ( open (SUMFILE, "<$sumfile") ) { 

	while ( <SUMFILE>) {
	    if (/max/) {
		chomp;
		@aux = split;
		if ( $aux[2] > -50) {
		    print "$name   $noc{$name}    @aux[2..4] \n";
		}
		
	    }
	}
	close SUMFILE;

    } else {
	print FAILFILE "$name\n";
    }
    
}

close PDBLIST;

close FAILFILE;
