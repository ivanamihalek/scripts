#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

if ( ! defined $ARGV[1] ) {
    die "Usage: ranks_energy.pl <ranks> <int_matrix> \n";
}
$ranksfile = $ARGV[0];
$intfile =  $ARGV[1];

$CUTOFF_CVG = 0.2;

open ( RANKS, $ranksfile) ||
    die "Cno 4ranksfile:$!\n";

while ( <RANKS> ) {
    next if ( /^%/ );
    next if ( !/\S/ );
    chomp;
    #($nr, $pid, $val, $int, $var, $subst, $rho, $cvg, $gaps) = split;
    ($nr, $pid, $val, $int, $var, $subst, $surf, $rho, $sub_rho, $compl_rho,  $cvg, $gaps) = split;
    $score{$pid} = $rho;
    next if ( $cvg eq "-" );
    next if ( $gaps > 0.3 );
    #last if ( $cvg > $CUTOFF_CVG );
    #printf " %5d     %1s    %20s    %5.3f \n", $pid, $val,  $subst, $cvg;
}

open ( INT, $intfile) ||
    die "Cno $intfile:$!\n";

while ( <INT> ) {
    ($pid1, $pid2, $energy, $dist1 , $dist2 ) = split;
    if ( ! defined $en{$pid1} ) {
	 $en{$pid1} = 0.0;
    }
    if ( ! defined $en{$pid2} ) {
	 $en{$pid2} = 0.0;
    }
    $en{$pid1} += $energy;
    $en{$pid2} += $energy;
}



close  INT;

foreach $pid ( keys %en ) {
    printf " %4d  %10.3e   %10.3e \n", $pid,$score{$pid},  $en {$pid};
}
