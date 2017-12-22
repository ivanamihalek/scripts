#!/usr/bin/perl -w

 

(defined $ARGV[3]) ||
    die "Usage:  $0  <infile> <pdb_id column> <score column>  <pdb_file_full_path>  [<chain>] \n"; 
($infile, $pdb_id_col, $score_col,  $pdb_file) = @ARGV;

$pdb_id_col -= 1;
$score_col  -= 1;

$chain = "";

defined $ARGV[4]  && ($chain = $ARGV[4]);

open (IN_FILE, "<$infile") || 
    die "cno $infile\n";
    

%score = ();
while ( <IN_FILE> ) {
    next if ( !/\S/ );
    @aux = split;
    $pdb_id = $aux[$pdb_id_col];
    next if ($pdb_id =~ '-' );
    $score{$pdb_id} = $aux[$score_col];
}
close(IN_FILE);

( scalar keys %score) || 
    die "no coverage found in $infile (?).\n";


open(FH_PDB, "<$pdb_file");

while(<FH_PDB>){
    if(!/^ATOM/){
        print "$_";
    }  else{
        $chain_pdb = substr($_, 21,1);
        if($chain ne ""){
            if($chain eq $chain_pdb){
                $pos = substr($_, 22,4);
                $pos =~ s/\s*//g;
		if (defined $score{$pos} ) {
		    $score = $score{$pos}*100;
		} else {
		    $score = 0.0;
		}
		$newBfactor = sprintf(" %6.2f", $score);
                $newline = $_;
		if (length($newline)<70) {
		    chomp $newline;
		    $newline .= " "x(70-length($newline))."\n";
		}
		substr($newline, 59,7, $newBfactor);
                print $newline; 
           } else{
               print "$_";
           } 
        } else{
            $pos = substr($_, 22,4);
            $pos =~ s/\s*//g;
	    if (defined $score{$pos} ) {
		$score = $score{$pos}*100;
	    } else {
		$score = 0.0;
	    }
            $newBfactor = sprintf(" %6.2f", $score);
            $newline = $_;
	    if (length($newline)<70) {
		chomp $newline;
		$newline .= " "x(70-length($newline))."\n";
	    }
            substr($newline, 59,7,$newBfactor);
            print $newline;
        }
    }
}

close(FH_PDB);
