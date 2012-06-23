#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

#$msf  = "all.msf";
$fasta  = "all.fasta";
$extr   = "/home/i/imihalek/perlscr/extractions/extr_seqs_from_fasta.pl";
$two    = "/home/i/imihalek/perlscr/two_seq_analysis.pl";
$cw     = "/home/protean2/LSETtools/bin/linux/clustalw -output=gcg -quicktree";

@namelist = ();

while ( <> ) {
    next if ( ! /\S/ );
    chomp;
    @aux = split;
    push @namelist, $aux[0];
}


for $ctr1 ( 0 .. $#namelist) {

    #print  " aaaaa $ctr1\n"; 
    for $ctr2 ( $ctr1+1 .. $#namelist) {
	open (NAMES  ,">tmp.names") ||
	    die "Cno tmp.names:$!.\n";
	print NAMES "$namelist[$ctr1]\n";
	print NAMES "$namelist[$ctr2]\n";
	close NAMES;
	
	$cmd = "$extr tmp.names $fasta > tmp.fasta";
        `$cmd`;
	
	`$cw -infile=tmp.fasta -outfile=tmp.msf > /dev/null`;
	if ( ! -e "tmp.msf" ) {
	    exit;
	}
	$ret =  `$two tmp.msf`;
	@aux = split ' ', $ret;
	#if ( $aux[5] > 0.25) {
	print $ret;
	#}
	
    }
}
