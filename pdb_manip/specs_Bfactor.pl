#!/usr/bin/perl -w

 

(defined $ARGV[2]) ||
    die "Usage:  $0  <method [rvet|ivet|entr|pheno|det]>  <specs score file>".
    "  <pdb_file_full_path>  [<chain> and/or -r and/or -b] \n"; 
($method, $ranks_file, $pdb_file) = @ARGV;

$chain = "";

if(defined $ARGV[3]){
    $chain = $ARGV[3];
}

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
	$pdb_id = $aux[0];
        #$resd = $aux[2];
        #print "~~~$pdb_id->$resd\n";
	next if ($pdb_id =~ '-' );
	$cvg{$pdb_id} = $aux[$method_column];
	#if ( $reverse ) {
	#    $cvg{$pdb_id} = 1 - $cvg{$pdb_id};
	#}
    }
}
close(RANKS_FILE);

( scalar keys %cvg) || 
    die "no coverage found in $ranks_file (?).\n";


open(FH_PDB, "<$pdb_file");

while(<FH_PDB>){
    if(!/^ATOM/){
        print "$_";
    }
    else{
        $chain_pdb = substr($_, 21,1);
        if($chain ne ""){
            if($chain eq $chain_pdb){
                $pos = substr($_, 22,4);
                $pos =~ s/\s*//g;
		if (defined $cvg{$pos} ) {
		    $score = $cvg{$pos}*100;
		} else {
		    $score = 100.0;
		}
		$newBfactor = sprintf(" %6.2f", $score);
                $newline = $_;
                substr($newline, 59,7, $newBfactor);
                print $newline; 
           } else{
               print "$_";
           } 
        } else{
            $pos = substr($_, 22,4);
            $pos =~ s/\s*//g;
	    if (defined $cvg{$pos} ) {
		$score = $cvg{$pos}*100;
	    } else {
		$score = 100.0;
	    }
            $newBfactor = sprintf(" %6.2f", $score);
            $newline = $_;
            substr($newline, 59,7,$newBfactor);
            print $newline;
        }  
    }
}
