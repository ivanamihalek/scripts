#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$rho_column = 7;

while ( <> ) {
    next if ( /^%/ );
    next if ( !/\S/ );
    chomp;
    @aux = split;
    next if ( $aux[1] ) =~ /\-/;

    #$pdb_pos = $aux[1];
    #$almt_pos{ $pdb_pos} = $aux[0];
    $rho{$aux[1]} = $aux[$rho_column -1];
    $aa{$aux[1]} = $aux[2];
}

%tmp = %rho;
@rho_sorted = sort HashByValue  (keys(%tmp));
$ctr = 0;
$rho_old = -1;

foreach $key ( @rho_sorted  ) {
    if ( $rho{$key} != $rho_old   && $rho_old > 0 ){
	$cvg_rho{$rho_old} = $ctr/$#rho_sorted;
    }
    $rho_old = $rho{$key};
    $ctr++;
}
$ctr--;
$cvg_rho{$rho_old} = $ctr/$#rho_sorted;



foreach $key ( @rho_sorted  ) {
    #if (   $cvg_sub_rho{$sub_rho{$key}} <= $CUTOFF_CVG && 
#	   $cvg_rho{$rho{$key}} >  $CUTOFF_CVG ) { 
	printf  "   %5d  %4s  %8.2f   %8.2f     \n", 
	$key,   $aa{$key}, $rho{$key}, $cvg_rho{$rho{$key}};
	
  #  }
}




sub  HashByValue {
    $tmp{$a} <=> $tmp{$b};
}

sub  InvHashByValue {
    $tmp{$b} <=> $tmp{$a};
}
