#!/usr/bin/perl -w

 

(defined $ARGV[4]) ||
    die "Usage:  $0  <method [rvet|ivet|entr|pheno|det]>  <specs score file> ".
    " <pdb_file_full_path> <cutoff cvg (%)>  <cutoff dist>  [<chain>] \n"; 
($method, $ranks_file, $pdb_file, $cutoff_cvg, $cutoff_dist) = @ARGV;

$clustercounter = "/home/ivanam/c-utils/pdb_clust/pc";

( -e $clustercounter) || die "$clustercounter not found.\n";

$timestr = time();
$hacked_pdbfile = "tmp$timestr.pdb";

$chain = "";

if(defined $ARGV[5]){
    $chain = $ARGV[5];
}

#######################################################3
open (RANKS_FILE, "<$ranks_file") || 
    die "cno $ranks_file\n";
    

$method_column = -1;
%cvg = ();
while ( <RANKS_FILE> ) {
    next if ( !/\S/ );
    if ( /\%/ ){
	@aux = split;
	shift @aux;
	for ($ctr=0; $ctr< $#aux; $ctr++) {
	    if ($aux[$ctr] eq $method ) {
		$method_column = $ctr;
		last;
	    }
	}
    } elsif ($method_column > -1) {
	chomp;
	@aux = split;
	$pdb_id = $aux[1];
	next if ($pdb_id =~ '-' );
	$cvg{$pdb_id} = $aux[$method_column];
    }
}
close(RANKS_FILE);

( scalar keys %cvg) || 
    die "no coverage found in $ranks_file (?).\n";

#######################################################3
open(PDB_IN, "<$pdb_file") || die "Cno $pdb_file: $!\n";

open(PDB_OUT, ">$hacked_pdbfile")|| die "Cno $hacked_pdbfile: $!\n";

while(<PDB_IN>){
    next if(!/^ATOM/);
    
    $chain_pdb = substr($_, 21,1);
    if( !$chain || ($chain  && $chain eq $chain_pdb)){
	$pos = substr($_, 22,4);
	$pos =~ s/\s*//g;
	if (defined $cvg{$pos} ) {
	    $score = $cvg{$pos}*100;
	} else {
	    $score = 100.0;
	}
	next if ( $score > $cutoff_cvg);
	$newBfactor = sprintf(" %6.2f", $score);
	$newline = $_;
	substr($newline, 59,7, $newBfactor);
	print PDB_OUT $newline; 
    } 
}

close PDB_IN;
close PDB_OUT;

#######################################################3

$ret = `$clustercounter $hacked_pdbfile $cutoff_dist`;

@lines = split "\n",  $ret;

foreach ( @lines ) {
    next if ( ! /\S/);
    if ( /cluster .+ (\d+)/ ) {
	$name = "cluster_$1";
	if ( defined $used{$name} ) {
	    $used{$name} ++;
	    $name .= "_".$used{$name};
	} else {
	    $used{$name} = 1;
	}
	@{$res{$name}} = ();
    } elsif ( /isolated/ ) {
 	$name = "isolated";
	@{$res{$name}} = ();
   } else {
	$resno = $_;
	$resno =~ s/\s//g;
	if  ( ! grep (/$resno/,  @{$res{$name}}) ) {
	    push @{$res{$name}}, $resno;
	}
    }
}


#######################################################3
foreach $name ( keys %res ) {
    print "select $name, resi ". join "+", @{$res{$name}};
    print "\n";
}




#######################################################3
`rm  $hacked_pdbfile`;
