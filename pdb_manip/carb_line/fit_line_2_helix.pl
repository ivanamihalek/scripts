#! /usr/bin/perl -w

use Math::Trig;


(@ARGV >= 3) ||
    die "Usage:  $0  <pdb>  <residue from>  <residue to>  [<chain>] \n";


($pdbtrj, $res_from, $res_to) = @ARGV;

$chain = "";
(defined $ARGV[3] )  && ($chain = $ARGV[3]);


$lsf3d = "/home/ivanam/c-utils/linear_ls_fit/three_dee/lsf3";


$filename = $pdbtrj;

open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

while ( <IF> ) {

    if (  /^ENDMDL/  ) {

	last;
 



    } elsif ( /^ATOM/ ) {

	next if ( $chain &&  ($chain ne substr ( $_,  21, 1)));

	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	next if ( $res_seq< $res_from ||  $res_seq> $res_to);

	$name = substr $_,  12, 4;     $name =~ s/\s//g; 
	
	#next if ( $name ne "N" && $name ne "C" && $name ne "O");
	next if ($name ne "CA");
	
	push @coords , (substr $_,30, 24);
	    
    }
}




@midpoints = ();
foreach $coord_ctr( 0 .. $#coords-2 ) {
    @point_m1 = split " ", $coords[$coord_ctr];
    @point = split " ",    $coords[$coord_ctr+1];
    @point_p1 = split " ", $coords[$coord_ctr+2];
    for ($i=0; $i<3; $i++) {
	$avg[$i] =  ($point_p1[$i]+ $point[$i]+  $point_m1[$i])/3;
    }
    push @midpoints, join  " ", @avg;
}



# fit 
open (TMP, ">tmp") || die "Cno tmp: $!.\n";
print TMP join "\n", @midpoints;
print TMP "\n";
close TMP;

	
$ret = `$lsf3d tmp`;
chomp $ret;

@line = split "\n", $ret;
@cm = split " ", $line[0];  shift @cm;
@p =  split " ", $line[1]; shift @p;

# check the direction
$dotprod = 0;
@begin =  split " ", $midpoints[0];
@end   =  split " ", $midpoints[$#midpoints];

for $i (0 .. 2) {
    $rough[$i] = $end[$i] - $begin[$i];
    $dotprod  += $rough[$i]*$p[$i];
}

if ($dotprod < 0 ) {
    for $i (0 .. 2) {
	$p[$i] = -$p[$i];
    }
}

print "  @p   @cm \n";
