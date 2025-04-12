#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined $ARGV[0] &&  defined $ARGV[1] && defined $ARGV[2]   ||
    die "Usage: gnuplot_ranks.pl <name> <start_alignment_postn>  <end_alignment_postn>  \n"; 
$name = $ARGV[0] ;
open ( RANKS, "<$name.ranks" ) ||
    die "Cno :$name.ranks  $!\n";

$s = $ARGV[1] ;
$e = $ARGV[2] ;
if ( defined $ARGV[3] ) {
    $format = $ARGV[3];
} else {
    $format = "post";
}
if ( defined $ARGV[4] &&  $ARGV[4] =~ "rho") {
    $column = 7;
} else {
    $column = 3;
}

$max = -1;
$min = 10000;
while ( <RANKS> ) {
    next if  (/^\%/ || ! (/\w/) );
    @aux = split;
    next if ( $aux[1] =~ '-' );
    if ( $max < $aux[$column] ) {
	$max = $aux[$column];
    }
    if ( $min >  $aux[$column] ) {
	$min = $aux[$column];
    }
}
printf "max is $max   min is $min\n";
seek RANKS, 0, 0;


open ( GPSCR, ">$name.gpscr")  || 
    die "Cno $name.gpscr: $! \n";
print GPSCR "set nokey\n";
print GPSCR "set title \"$name\" \n";
print GPSCR "set yrange [0:1.1]\n";
print GPSCR "set ylabel \"relative importance\" \n";
print GPSCR "set xtics rotate  ( ";

open ( TMP, ">tmp") || 
    die "Cno tmp: $! \n";


$ctr = 0;
$first = 1;
while ( <RANKS> ) {
    next if  (/^%/ || ! (/\w/) );
    @aux = split;
    next if ( $aux[1] =~ '-' );
    if ( $aux[0] >= $s &&   $aux[0] <= $e) {
	$ctr++;

	$rescaled = ($max+$min-$aux[$column])/$max;


	printf TMP " %5d     %5.3f  \n", $ctr, $rescaled;
	if ( $first ) {
	    $first = 0;
	} else {
	    printf GPSCR ", "; 
	}
	printf GPSCR " \"$aux[5]:  $aux[1] \"   $ctr ";
    }
}


close TMP;



 printf GPSCR ")\n"; 
print GPSCR "set term $format\n";
if ( $format =~ "post" ) {
    $ext = "ps";
} else {
    $ext = $format;
}
print GPSCR "set output \"$name.$ext\" \n";
print GPSCR "plot \"tmp\" u 1:2 w boxes \n";
close GPSCR;
