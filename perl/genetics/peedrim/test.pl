#!/usr/bin/perl -w

@region = ();

while ( <> ) {
    chomp;
    push @region, $_;

}

($temp_origin) = ($from, $to, $count) = split " ", $region[0];

($avg, $avg_sq, $avg_mid, $avg_mid_sq) = (0,0,0,0);
$tot = 0;


foreach $hit ( @region ) {
    ($from, $to, $count) = split " ", $hit;
    
    $from -= $temp_origin;
    $to   -= $temp_origin;

    $length    = $to - $from + 1;
    $length_sq = $length*$length;
    $avg      += $length*$count;
    $avg_sq   += $length_sq*$count;

    $tot += $count;

    $mid_seq     = ($to + $from)/2;
    $mid_sq      = $mid_seq*$mid_seq;
    $avg_mid    += $mid_seq*$count;
    $avg_mid_sq += $mid_sq *$count;

    print " $from   $to      $length  $mid_seq   $count\n";
}
$avg        /= $tot;
$avg_sq     /= $tot;
$avg_mid    /= $tot;
$avg_mid_sq /= $tot;

$region_hits = $tot;
$region_avg_length   = sprintf "%4.1f", $avg;
$region_length_stdev = sprintf "%4.1f", sqrt($avg_sq - $avg*$avg);
$region_avg_mid      = sprintf "%4.1f", ($avg_mid);
#$region_avg_mid      = sprintf "%4.1f", ($avg_mid+$temp_origin);
$region_avg_mid_sq   = sprintf "%4.1f", sqrt($avg_mid_sq - $avg_mid*$avg_mid);
print "\n\t $avg_mid_sq    $avg_mid\n";
   

print "total:  $region_hits    ".
    "length: $region_avg_length p/m $region_length_stdev \n";
print  "average mid position = $region_avg_mid p/m $region_avg_mid_sq\n";	
