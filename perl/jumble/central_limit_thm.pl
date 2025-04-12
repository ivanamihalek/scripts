#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

use strict;

my $sample_size = 14; # N

my $pool_size = 500;

my $number_of_samplings = 1000;

my $number_of_bins = 20;

my $bin_width = $pool_size/$number_of_bins;


my ($bin, $s, $avg, $draw, $score, @population);

for $bin ( 1  .. $number_of_bins ) { 
    $population[$bin] = 0;
}


for $s ( 1 .. $number_of_samplings ) { 
    $avg = 0;
    for $draw ( 1.. $sample_size ) { 
	$score = int (rand($pool_size)) + 1;
	$avg += $score; 
    }
    $avg /= $sample_size; 

    for $bin ( 1  .. $number_of_bins ) { 
	if ( $avg <($bin)*$bin_width ) { 
	    $population[$bin] ++; 
	    last;
	} 
    }

} 

 for $bin ( 1  .. $number_of_bins ) {
     
     printf " %4d  %4d  %5d \n", 
     ($bin-1)*$bin_width, ($bin)*$bin_width, $population[$bin];
 }
