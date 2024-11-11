#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( defined $ARGV[0] ) || 
    die "Usage: spearman.pl  <file_name. [ <col1> <col2> [<weight col>]] . \n";

$file =  $ARGV[0];

# default columns
$column1 = 0;
$column2 = 1;
$weight_column = -1;
$read_weight = 0;

if ( defined $ARGV[2] ) {
    $column1 = $ARGV[1]-1;
    $column2 = $ARGV[2]-1;
}
if ( defined $ARGV[3] ) {
    $weight_column =  $ARGV[3]-1;
}

if ( $weight_column >= 0 ) {
    $read_weight = 1;
}

@r = ();
@s = ();

open (IF, "<$file") ||
    die "Cno $file: $!.\n";

while ( <IF> ) {
    next if (/^%/);
    next if (!/\S/);
    @aux = split;
    push @r, $aux[$column1];
    push @s, $aux[$column2];
    if ( $read_weight ) {
	$weight =  $aux[$weight_column];
	foreach  ( 2 .. $weight) {
	    push @r, $aux[$column1];
	    push @s, $aux[$column2];
	}
    }
}
close IF;

$max = $#r;
$max || exit;

@r_sort = sort @r;
@s_sort = sort @s;



for $i ( 0 .. $max) {
    for $j ( 0 .. $max) {
	if ( $r[$i] == $r_sort[$j] ) {
	    $rank_r[$i] = $j+1;
	    last;
	}
    }
}



for $i ( 0 .. $max) {
    for $j ( 0 .. $max) {
	if ( $s[$i] == $s_sort[$j] ) {
	    $rank_s[$i] = $j+1;
	    last;
	}
    }
}

=pod
print join " ", @rank_r, "\n";
print join " ", @rank_s, "\n";
exit;
=cut


$avg_r = 0;
$avg_s = 0;
for $i ( 0 .. $max) {
    $avg_r += $rank_r[$i];
    $avg_s += $rank_s[$i];
}

$avg_r /= ($max+1);
$avg_s /= ($max+1);


$sum  = 0;
$s_sq = 0;
$r_sq = 0;



for $i ( 0 .. $max) {
    $sum  += ($rank_r[$i]-$avg_r)*($rank_s[$i]-$avg_s);
    $s_sq += ($rank_s[$i]-$avg_s)*($rank_s[$i]-$avg_s);    
    $r_sq += ($rank_r[$i]-$avg_r)*($rank_r[$i]-$avg_r);
}


$corr = $sum / sqrt( $s_sq*$r_sq);

$signf = $corr*sqrt(   ($max+1-2)/(1-$corr*$corr) );
printf "%8.3f  %8.3f\n", $corr, $signf;
