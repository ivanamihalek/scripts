#! /usr/gnu/bin/perl -w

$name = "1jm4";

for $i ( 1..25 ) {
    $filename = "$name.i.$i.cluster_report.summary";
    open ( FH, "<$filename") || 
	die "Cno $filename: $!\n";
    $filename = "$name.i.$i.summary.logtable";
    open ( OFH, ">$filename") || 
	die "Cno $filename: $!\n";
    printf "$filename:\n";
    while ( <FH> ) {
	last if (/Rank/);
    }
    while ( <FH> ) {
	last if (/not done/);
	@aux = split;
	printf ( OFH "%4d %8.3lf %8.3lf \n", $aux[0],abs( log ($aux[3])), abs (log ($aux[5])) );
    }

    close FH;
    close OFH;
}
