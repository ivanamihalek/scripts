#! /usr/bin/perl -w

defined ( $ARGV[0]  ) ||
    die "Usage: $0   <pdb_file>   [<chain_name>].\n";

$pdbfile = $ARGV[0];
if ( defined $ARGV[1] ) {
    $query_chain_name =$ARGV[1] ;
} else {
    $query_chain_name ="" ;
}

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$exceptions = "ACE_PCA_DIP_NH2_LTA_MSE";
%seen = ();
while ( <IF> ) {

    last if ( /^ENDMDL/);
    #last if ( /^TER/);
    next if ( ! /^ATOM/ && ! /^HETATM/ );
    $chain_name = substr ( $_,  21, 1) ;
    next if ( $query_chain_name &&   $chain_name ne " "  && 
	      $chain_name ne $query_chain_name );
    $res_name = substr $_,  17, 3; $res_name =~ s/\s//g;
    next if ( /^HETATM/ && $exceptions !~ $res_name );

    #try to handle insertion code cases:
    $res_seq   = substr $_, 22, 5;  $res_seq=~ s/\s//g;

    $atom_name = substr $_, 12, 4; $atom_name=~ s/\s//g;
    if ( ! defined $seen{"*res_seq $atom_name" } ){
	$seen{"$res_seq $atom_name"} = 1;
	print $_;
    }
    
}

close IF;
