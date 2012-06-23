#! /usr/bin/perl -w

defined $ARGV[0] ||
    die "Usage: pdbepi2almtepi.pl <name_list> \n";

open ( FF, "<$ARGV[0]")  ||
    die "Cno $ARGV[0]: $! \n";

while ( <FF> ) {
    chomp;
    @aux = split'\.'; 
    $name = $aux[0];
    $ranksfile = $name.".ranks";

    if ( ! -e  $ranksfile ) {
	print "$ranksfile missing\n";
	next;
    } 


    $epifile = $name.".almt_epitope";
    if ( ! -e  $epifile ) {
	print "$epifile missing\n";
	next;
    } 
    open (EPI, "<$epifile") ||
	die "Cno  $epifile: $! \n";
    @epitope = ();
    $ctr = 0;
    while ( <EPI>) {
	if ( /\w/ ) {
	    chomp;
	    @aux= split;
	    $num = shift @aux;
	    $epitope [$ctr ] = $num;
	    $line [$ctr] = join ' ', @aux;
	    $ctr ++;
	}
    }
    close EPI;


    open (RANKS, "<$ranksfile") ||
	die "Cno  $ranksfile: $! \n";

    while ( <RANKS> ) {
	next if ( /%/ );
	if ( /\w/ ) {
	    chomp;
	    @aux = split;
	    $almt2pdb{$aux[0]} = $aux[1];
	    
	}
    }

    close RANKS;

    $epifile = $name.".pdb_epitope";
    open (EPI_NEW, ">$epifile") ||
	die "Cno  $epifile: $! \n";

    for $ctr( 0 .. $#epitope) {
	$translation = $almt2pdb {$epitope[$ctr] };
	print EPI_NEW "$translation   $line[$ctr]\n";
	print   "$translation   $line[$ctr]\n";
	
    }
    close EPI_NEW;
 
}

close FF;
