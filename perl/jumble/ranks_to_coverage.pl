#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$rho_column = 7; # <===================== !!!!
printf "%%  %5s  %5s   %5s  %14s    %14s    %14s  %14s %14s   \n", 
    "id",   "almt pos", "aa_type","cvg in subtree", "cvg in complement" ,  
    "overall cvg", "compl-sub", "new cvg"; 

while ( <> ) {
    next if ( /^%/ );
    next if ( !/\S/ );
    chomp;
    @aux = split;
    next if ( $aux[1] ) =~ /\-/;
    $gaps = pop @aux;
    next if ( $gaps >= 0.33 );
    $pdb_pos = $aux[1];
    $almt_pos{ $pdb_pos} = $aux[0];
    $aa_type{ $pdb_pos} = $aux[2];
    $rho{$aux[1]} = $aux[$rho_column -1];
    $sub_rho{$aux[1]} = $aux[$rho_column ];
    $compl{$aux[1]} = $aux[$rho_column+1];
}

%tmp = %rho;
@rho_sorted = sort HashByValue  (keys(%tmp));
$ctr = 0;
foreach $key ( @rho_sorted  ) {
    $ctr++;
    $cvg_rho{$key} = $ctr/$#rho_sorted;
}


%tmp = %sub_rho;
@sub_rho_sorted = sort HashByValue  (keys(%tmp));
$ctr = 0;
foreach $key ( @sub_rho_sorted  ) {
    $ctr++;
    $cvg_sub_rho{$key} = $ctr/$#sub_rho_sorted;
}


%tmp = %compl;
@compl_sorted = sort HashByValue  (keys(%tmp));
$ctr = 0;
foreach $key ( @compl_sorted  ) {
    $ctr++;
    $cvg_compl{$key} = $ctr/$#compl_sorted;
}



foreach $key ( @sub_rho_sorted  ) {
    $diff{$key} =  $cvg_sub_rho{$key}-$cvg_rho{$key};
}




%tmp = %diff;
@diff_sorted = sort HashByValue  (keys(%tmp));
$ctr = 0;
foreach $key ( @diff_sorted ) {
    $ctr++;
    $cvg_diff{$key} = $ctr/$#compl_sorted;
}
foreach $key ( @diff_sorted  ) {
    printf "   %5d  %5d  %5s   %14.2f    %14.2f    %14.2f    %14.2f    %14.4f    \n", 
    $key,  $almt_pos{$key}, $aa_type{$key}, $cvg_sub_rho{$key}, $cvg_compl{$key} ,  
    $cvg_rho{$key}, $diff{$key}, $cvg_diff{$key};

}



sub  HashByValue {
    $tmp{$a} <=> $tmp{$b};
}

sub  InvHashByValue {
    $tmp{$b} <=> $tmp{$a};
}
