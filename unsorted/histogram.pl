#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
# FH -> autoflush(1);


if ( defined $ARGV[0] && defined $ARGV[1] ) {
    $filename = $ARGV[0];
    $col =  $ARGV[1] - 1;
    
} else {
    die "Usage: histogram.pl <filename>  <column> [<no of bins> <bin width> <start_value>].\n";
}

if ( defined $ARGV[2] ) {
    $no_bins = $ARGV[2];
} else {
    $no_bins = 10;
}

open ( FH, "<$filename") || die "Cno $filename: $!\n";
while ( <FH> ) {
    next if (/^\%/);
    next if ( !/\S/);
    chomp;
    @aux = split; 
    $val = $aux[$col];
    push @array, $val;
    if ( ! (defined $min) || $min > $val) {
	$min = $val;
    }
    if ( ! (defined $max) || $max < $val) {
	$max = $val;
    } 
    
}
close FH;
( defined $ARGV[4] ) && ( $min =  $ARGV[4]);

$span = $max - $min;

if ( defined $ARGV[3] ) {
    $bin_size = $ARGV[3];
} else {
    $bin_size = $span/$no_bins;
}

for $i (1 .. $no_bins ) {
    $bincnt[$i] = 0;
}

foreach $val ( @array ) {
    for $i (1 .. $no_bins ) {
	if ($val <= $min + $i*$bin_size ) {
	    $bincnt[$i]++;
	    last;
	}
    }
}

# zscore
$total = 0;
$avg = 0;
$avg_sq = 0;
for $i (1 .. $no_bins ) {
    $avg    += ($min +($i-1)*$bin_size/2)*$bincnt[$i];
    $avg_sq += ($min +($i-1)*$bin_size/2)*($min +($i-1)*$bin_size/2)*$bincnt[$i];
    $total  +=  $bincnt[$i];
}

$avg /= $total;
$avg_sq /= $total;
if (  $avg_sq  <=  $avg*$avg ) {
    die "Error: avg_sq =  $avg_sq      avg^2 =   ". $avg*$avg;
}

$sigma = sqrt ( $avg_sq  - $avg*$avg);

for $i (1 .. $no_bins ) {
    $z =  ($min +($i-1)*$bin_size/2 - $avg )/$sigma;
    printf "%10d   %8.3e - %8.3e    %10d   %8.1f\n",  
    $i, $min +($i-1)*$bin_size, $min +$i*$bin_size, $bincnt[$i], $z;
}

printf "\n\n%% total : %10.4f\n\n", $total;
