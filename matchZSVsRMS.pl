#!/usr/bin/perl -w

$listFile = $ARGV[0];
open(L_FILE,"<$listFile") || die "can't open $listFile.\n";
@proList = <L_FILE>;
close L_FILE;

match_zs_vs_rms();
#
sub match_zs_vs_rms{
    
    foreach(@proList){
	chomp $_;
	#if(chdir $_){
	    open(P_LIST,"<list") || die "can't open list for $_ . \n";
	    open(OUT_FILE,">zs.sum") || die "can't open zs.sum for $_.\n";
	    print OUT_FILE "#pdb\trmsd\tTotalS\tTotalA\tTotalSA\tMaxS\tMaxA\tMaxSA\n";

	    #determine the rmsd of each decoy structure
	    while($pdb = <P_LIST>){
		chomp $pdb;
		$pdb =~ /(.+)\.pdb/;
		$pdb_name = $1;

                #determine the rmsd of each decoy structure
		if($pdb_name eq $_){
		    $rms = 0.000;
		}else{
		    $rmsStr=`grep $pdb rmsds`;
		    @rmsStrV = split /\s+/,$rmsStr; 
		    $rms = pop @rmsStrV;
		}

		$sumFile = $pdb_name.".cluster_report.summary"; 
		open(S_FILE,"<$sumFile") || die "can't open $sumFile.\n";
		while($line = <S_FILE>){
		    if($line =~ /total score/){
			@tsV = split /\s+/,$line;
		    }

		    if($line =~ /max score/){
			@msV = split /\s+/,$line;
		    }
		    
		}
		
		print OUT_FILE "$pdb_name\t$rms\t$tsV[3]\t$tsV[4]\t$tsV[5]\t$msV[3]\t$msV[4]\t$msV[5]\n";
	    }


	    #chdir "..";
	#}else{
	    #print "Warning: can't access $_ directory.\n";
	#}
    }

}
