#! /usr/bin/perl -w
# find box around set of PDB coords - for docking

use IO::Handle;         #autoflush
# FH -> autoflush(1);


(defined $ARGV[0] ) ||
    die "usage: coordbox.pl   <pdbfile> \n.";


$pdbfile = $ARGV[0];



open (PDBFILE, "<$pdbfile") ||
    die "could not open $pdbfile.\n";

$point_ctr = 0;
while ( <PDBFILE> ) {
    next if ( ! /^ATOM/  && !/^HETATM/ );
    next if ( substr ($_, 26, 1) =~ /\S/) ;
    chomp;

    $c[0] = substr $_,30, 8;  $c[0]=~ s/\s//g;
    $c[1] = substr $_,38, 8;  $c[1]=~ s/\s//g;
    $c[2] = substr $_,46, 8; $c[2]=~ s/\s//g;


    for $ctr(0..2)  {
	$center[$ctr] += $c[$ctr]
    }
    $point_ctr ++;
 
}
close PDBFILE;








for $ctr (0 ..2 )  {
    $center[$ctr] /= $point_ctr;
    printf " %8.4f ",  $center[$ctr];
}
print "\n";
