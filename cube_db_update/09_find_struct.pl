#!/usr/bin/perl -w 

use strict;
use DBI;



sub GenerateSeqfile(@);
sub formatted_sequence(@);
sub generic_query (@);
sub oneliner (@);



my $db_pdb = "/var/www/dept/bmad/htdocs/projects/EPSF/struct_server/db/pdbfasta/pdbaa";
my $tmpdir ="/tmp";
#my $dir = "/home/ivanam/projects/cube_db/scratch/families";
my $blastp = "/var/www/dept/bmad/htdocs/projects/EPSF/specs_server/bin/ncbi-blast-2.2.25+/bin/blastp";

my $pdb_dir = "/var/www/dept/bmad/htdocs/projects/EPSF/struct_server/db/pdb";
my $pdb_extr_chain = "/var/www/dept/bmad/htdocs/projects/EPSF/specs_server/scripts/pdb_extract_chain.pl";
my $pdb2seq = "/var/www/dept/bmad/htdocs/projects/EPSF/specs_server/scripts/pdb2seq.pl";


   
# traverse all dirs - wnerever we find a pymol or chimera script,
# we turn it into a session
# we assume we are running this from the data dir	
     



my $home = `pwd`; chomp $home;
my @dirs = split "\n", `ls`;
foreach my $family(@dirs){

     # main level

    # into family dir
    chdir "$home/$family";
    print "$family: \n";


    my @cluster_dirs = split "\n", `ls -d cluster*`;
    foreach my $cluster (@cluster_dirs) {
        print "\t $cluster: \n";

        chdir "$home/$family/$cluster";

        #my @members = split "\n", `cat members`;

	my @pdb_found_incluster = ();
	
	if(-d "$home/$family/$cluster"){

	    my $clstr_dir = "$home/$family/$cluster";

	    chdir($clstr_dir);
	    my @members = split "\n", `cat members`;
    

  
	    foreach my $member(@members){
	

		my $cmd = "$blastp -query $member/$member.fasta -outfmt 6 -max_target_seqs 1 -db $db_pdb";
	
	
		my $blast_result = `$cmd`;
		chomp($blast_result);
	
	   

		if($blast_result){
		    my @aux = split(/\s+/, $blast_result);
		    my @subs = split(/\|/,$aux[1]);
		    my $pdb = lc($subs[$#subs-1]);
		    my $aln_len = $aux[3];
		    my $identity = $aux[2];

		    my $chain=0;
		    if($subs[$#subs]){
			$chain = $subs[$#subs];
		            	
		    }
###########################################################
# if find the 100% match keep the structure for each member	    
		    if($aux[2] eq "100.00"){
			my $pdb = lc($subs[$#subs-1]);
			my $pdb_subdir = substr($pdb, 1, 2);
		
			if(-e "$pdb_dir/$pdb_subdir/pdb$pdb.ent"){
			    if($chain){ #if there is chain id extract chain directly
				my $cmd;
				$cmd = "$pdb_extr_chain $pdb_dir/$pdb_subdir/pdb$pdb.ent $chain > $clstr_dir/$member/$pdb$chain.pdb";
			
				`$cmd`;

				$cmd = "$pdb2seq $clstr_dir/$member/$pdb$chain.pdb > $clstr_dir/$member/$pdb$chain.seq";
				`$cmd`;
			
			    }
			    else{ #if there is on chain id just cp the pdb file to the corespond member diretory
				my $cmd = "cp $pdb_dir/$pdb_subdir/pdb$pdb.ent > $clstr_dir/$member/$pdb.pdb";
				`$cmd`;
			
				$cmd = "$pdb2seq $clstr_dir/$pdb.pdb > $clstr_dir/$pdb.seq";
				`$cmd`;
			    }
		    
		    
			}
		    }
#######################################################
# push all blast output
		    if($aux[2] >= 30){		
			push(@pdb_found_incluster, "$pdb->$chain->$identity->$aln_len->$member");	
		    }
		}
	
	    }

#######################################################
# select one structure as the mapping structure for 
# whole cluster
	    my $pdb_selected = 0;
	    my @proteins_incluster = ();

	    foreach my $i(0..$#pdb_found_incluster){

		my $blast_out = $pdb_found_incluster[$i];
		if(!$pdb_selected){
		    $pdb_selected = $blast_out;
		
		}
		else{
		    my @aux_selected = split("->", $pdb_selected);
		    my @aux_aux = split("->", $blast_out);
		    if($aux_selected[2] < $aux_aux[2]){
		    
			
			$pdb_selected = $blast_out;
		    }
		    elsif($aux_selected[2] == $aux_aux[2]){
			if($aux_selected[3]<$aux_aux[3]){
			    $pdb_selected = $blast_out;
			}
		
		    }
		
		}
	    }

####################################################
# here is for the whole cluster just choose the best 
# hit among all members	  
  
	    if($pdb_selected){
	
		my @tmp_holder = split(/->/,$pdb_selected);
		my $pdb_nm = $tmp_holder[0];
		my $pdb_subdir = substr($pdb_nm, 1,2);
		my $chainid = $tmp_holder[1];
	
		if(-e "$pdb_dir/$pdb_subdir/pdb$pdb_nm.ent"){
		    if($chainid){
			my $cmd = "$pdb_extr_chain $pdb_dir/$pdb_subdir/pdb$pdb_nm.ent $chainid > $clstr_dir/$pdb_nm$chainid.pdb";
			`$cmd`;
		
			$cmd = "$pdb2seq $clstr_dir/$pdb_nm$chainid.pdb > $clstr_dir/$pdb_nm$chainid.seq";
			`$cmd`;
		
		    }
		    else{
			my $cmd = "cp $pdb_dir/$pdb_subdir/pdb$pdb_nm.ent $clstr_dir/$pdb_nm.pdb";
			`$cmd`;

			$cmd = "$pdb2seq $clstr_dir/$pdb_nm.pdb > $clstr_dir/$pdb_nm.seq";
			`$cmd`;
		    }
	    
		}

		my $protein = pop(@tmp_holder); #keep protein name used for blast which will be used in html display later on
		pop(@tmp_holder); #don't need alignment length, so pop it out
		$pdb_selected = join("->",@tmp_holder);
		$pdb_selected .= "->" . $protein; #put protein back

####################################################################
# write a file to keep struct information for html displaying
		open(FH, ">$clstr_dir/struct_info") || die "Cno $clstr_dir/struct_info";
		print FH "$pdb_selected\n";
		close(FH);
	
	    }
       
	}
    }
}
