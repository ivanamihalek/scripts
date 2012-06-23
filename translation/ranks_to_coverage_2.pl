#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$CUTOFF_CVG = 0.30;

$rho_column = 7;

while ( <> ) {
    next if ( /^%/ );
    next if ( !/\S/ );
    chomp;
    @aux = split;
    next if ( $aux[1] ) =~ /\-/;

    $pdb_pos = $aux[1];
    $almt_pos{ $pdb_pos} = $aux[0];
    $rho{$aux[1]} = $aux[$rho_column -1];
    $sub_rho{$aux[1]} = $aux[$rho_column ];
    $compl{$aux[1]} = $aux[$rho_column+1];
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


%tmp = %sub_rho;
@sub_rho_sorted = sort HashByValue  (keys(%tmp));
$ctr = 0;
$rho_old = -1;
foreach $key ( @sub_rho_sorted  ) {
    if ( $sub_rho{$key} != $rho_old  && $rho_old > 0) {
	$cvg_sub_rho{$rho_old} = $ctr/$#sub_rho_sorted;
    }
    $rho_old  =   $sub_rho{$key};
    $ctr++;
}
$ctr--;
$cvg_sub_rho{$rho_old} = $ctr/$#rho_sorted;


%tmp = %compl;
@compl_sorted = sort HashByValue  (keys(%tmp));
$ctr = 0;
$rho_old = -1;
foreach $key ( @compl_sorted  ) {
    if (  $compl{$key} != $rho_old  && $rho_old > 0) {
	$cvg_compl{$rho_old} = $ctr/$#compl_sorted;
    }
    $rho_old = $compl{$key};
    $ctr++;
}
$ctr--;
$cvg_compl{$rho_old} = $ctr/$#compl_sorted;

foreach $key ( @sub_rho_sorted  ) {
    #if (   $cvg_sub_rho{$sub_rho{$key}} <= $CUTOFF_CVG && 
#	   $cvg_rho{$rho{$key}} >  $CUTOFF_CVG ) { 
	printf  "   %5d  %5d   %8.2f    %8.2f    %8.2f    \n", 
	$key, $almt_pos{$key},  $cvg_sub_rho{$sub_rho{$key}},  $cvg_compl{$compl{$key} },  $cvg_rho{$rho{$key}};
	
  #  }
}




sub  HashByValue {
    $tmp{$a} <=> $tmp{$b};
}

sub  InvHashByValue {
    $tmp{$b} <=> $tmp{$a};
}
