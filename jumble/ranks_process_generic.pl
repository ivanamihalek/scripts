#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$CUTOFF_CVG = 0.2;

while ( <> ) {
    next if ( /^%/ );
    next if ( !/\S/ );
    chomp;
    ($nr, $pid, $val, $int, $var, $subst, $rho, $sub_rho, $sub_compl, $cvg, $gaps) = split;
    next if ( $cvg eq "-" );
    last if ( $cvg > $CUTOFF_CVG );
    printf " %5d     %1s    %20s    %5.3f \n", $pid, $val,  $subst, $cvg;
}
