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
	
	next if ( $name ne "N" && $name ne "C");
	
	push @coords , (substr $_,30, 24);
	    
    }
}



# fit 
open (TMP, ">tmp") || die "Cno tmp: $!.\n";
print TMP join "\n", @coords;
print TMP "\n";
close TMP;

	
$ret = `$lsf3d tmp`;
chomp $ret;

@line = split "\n", $ret;
@cm = split " ", $line[0];  shift @cm;
@p =  split " ", $line[1]; shift @p;


# check the direction
$dotprod = 0;
@begin =  split " ", $coords[0];
@end   =  split " ", $coords[$#coords];

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
