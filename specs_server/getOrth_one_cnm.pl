#!/usr/bin/perl -I/usr/local/lib/perl5/site_perl/5.8.0/sun4-solaris/DBI/ -I/var/www/dept/bmad/htdocs/projects/EPSF/struct_server/scripts/SendMail-2.09
###############################################################################
#Date: 23 Oct. 2007                                                           #
#Script: getOrthologues.pl                                                    #
#Author:Zhang Zong Hong                                                       #
#Purpose: extract orthologues from database, ensembl installed on localhost   #
#Usage: perl getOrthologues.pl geneListFileName                               # 
###############################################################################


use DBI;
use SendMail;

use lib '/var/www/dept/bmad/htdocs/projects/EPSF/struct_server/scripts';
use MiscUtil;

sub generic_query (@);
sub oneliner (@);
sub formatted_sequence ( @);
sub hash_dictionary(@);
sub getCommonNm(@); 
#mailme("specs","test");
$numArgs = $#ARGV;
$scratchdir = "/tmp";

if($numArgs < 1){
    print "Usage: getOrthologus Gene_name(for gene names) jobID\n";
    exit(1);  
}
$jobID = $ARGV[1];
$myjobdir = "$scratchdir/specs_$jobID";
@genefile_list=();
#print "$myjobdir\n";

open(FHANDLE,"<$ARGV[0]")|| die("Could not open file!");
@geneNlist = <FHANDLE>;
close(FHANDLE); 


$db_info = "DBI:mysql:database=epsf_ensembl:host=jupiter.private.bii:port=3308";
$db_usr = "epsfdbusr";
$db_pswd = "5yhx7xaC";

@geneN_notfound=();
$dbh = DBI->connect($db_info, $db_usr, $db_pswd, {RaiseError=>1,PrintError=>1});

foreach(@geneNlist){
    next if(/^$/);
    $geneN = $_;
    chomp($geneN);
    #if(-e $geneN){$cmd = "rm -r $geneN"; system($cmd);}
    #mkdir($geneN,0777) || die "can not mkdir $geneN: $!";
    $fastaFN= $geneN . ".fasta";
    $fastafile = "$myjobdir/$fastaFN";
    
    $query = "SELECT distinct stable_id FROM gene_nm_stableId ";
    $query .= "WHERE display_label = '$geneN'";
    #$query .= " and stable_id LIKE 'ENSG%'";#this because some gene's has a stable_id contain LRG(Locus Reference Genomic) for diagnosis purpose
                                            #we do need this in our case
    ($gid)=oneliner($query);
    
    
    
    if(!defined($gid) || !$gid ){
	$query = "SELECT distinct stable_id FROM gene_syn_stableId ";
	$query .= "WHERE synonym = '$geneN'";
	#$query .= " and stable_id LIKE 'ENSG%'"; #this because some gene's has a stable_id contain LRG(Locus Reference Genomic) for diagnosis purpose
                                                 #we do need this in our case

	($gid)=oneliner($query);
	if(!defined($gid) || !$gid ){
	    push(@geneN_notfound, $geneN);
	
	    next;
	}
    }

        ##retrieve gene_stable_id of orthologues
    $query = "SELECT m1.stable_id, hm1.peptide_member_id, m2.stable_id, hm2.peptide_member_id, h.description, g.name, ";
    $query .= "g.common_name, g.group_id ";
    $query .= "FROM member m1, member m2, homology_member hm1,homology_member hm2, ";
    $query .= "homology h, genome_db g ";
    $query .= "WHERE m1.stable_id = '$gid' ";
    $query .= "AND m1.member_id = hm1.member_id ";
    $query .= "AND hm1.homology_id = h.homology_id ";
    $query .= "AND h.homology_id = hm2.homology_id ";
    $query .= "AND hm2.member_id = m2.member_id ";
    $query .= "AND m2.genome_db_id = g.genome_db_id ";
    $query .= "AND h.description LIKE '%ortholog%one2one' ";
    $query .= "AND m2.stable_id <> '$gid' ORDER BY g.name";

    @ortholog_gstable_idgroup = generic_query ($query);
        
    #get sequence_id for query gene, 
    #all query gene peptide_member_id in the records retreived are same
    #first one is chosen here  
    $tmp_ptr = $ortholog_gstable_idgroup[0];
    $gene_pep_member_id=${$tmp_ptr}[1];
    $query = "SELECT s.sequence from member m, sequence s ";
    $query .= "WHERE m.member_id = '$gene_pep_member_id' ";
    $query .= "AND s.sequence_id = m.sequence_id";

    ($sequence) = oneliner($query);
    if(!$sequence){
        push(@geneN_notfound, $geneN);        
    }
    else{
	($format_sequence) = formatted_sequence($sequence);
	#@genome_cnm = ();
	if($format_sequence){
	    open(FILEH, ">$fastafile");
	    #print ">$geneN\n$format_sequence\n";  
	    print FILEH ">HOM_SAP_$geneN\n$format_sequence\n";
	    %genome_cnm = ();
	    push(@{$genome_cnm{1}},"HOM_SAP_$geneN\t$gid\thomo_sapiens(human)");
	    foreach $array_ptr(@ortholog_gstable_idgroup){
		($gene_stable_id, $gene_pep_member_id, $or_gene_stable_id, $or_pep_member_id, $desc, $genome_name,$g_cnm,$g_groupid)=@{$array_ptr};
		$query = "SELECT s.sequence,s.sequence_id from member m, sequence s ";
		$query .= "WHERE m.member_id = '$or_pep_member_id' ";
		$query .= "AND s.sequence_id = m.sequence_id";
		($or_sequence,$sq_id) = oneliner($query);
		($format_or_sequence) = formatted_sequence($or_sequence);
		if($genome_name =~ /_/){
		    @aux = split "_", $genome_name;
		}
		elsif($genome_name =~ /\s/){
		    @aux = split " ", $genome_name;
		}
		else{
		    print "Problem with naming\n";
		    exit;
		}
		$new_name = join "_", (uc  substr ($aux[0], 0, 3), 
				   uc  substr ($aux[1], 0, 3), $geneN);
                
	    

		push(@{$genome_cnm{$g_groupid}},"$new_name\t$or_gene_stable_id\t$genome_name($g_cnm)");

		print FILEH  ">$new_name\n$format_or_sequence\n";
		
 
	    }     
	    close(FILEH);
	    open(SPECIES, ">$myjobdir/$geneN.species") || die ("error open $myjobdir/$geneN.species");
	    open(FH, ">$myjobdir/$geneN.name") || die ("error open $myjobdir/$geneN.name");
	    #print FH "name $geneN\n";
	    foreach $genome(sort {$a <=> $b} keys %genome_cnm){
		#print "$genome->\n";
		foreach $ele(@{$genome_cnm{$genome}}){
		    my @tmp = split(/\s/,$ele);
		    print FH "$tmp[0]\n";
		    print SPECIES "$tmp[2]\n";

		}
	    }
	    close(FH);
	    close(SPECIES);
	}
    }
   

}

$dbh->disconnect;
#die ("sth is wrong");
if(defined(@geneN_notfound) && @geneN_notfound){
    foreach $g(@geneN_notfound){
	print"$g\n";
    }
}

#open(FH, ">$myjobdir/name.list") || die ("error");

#foreach $k(sort keys %genome_cnm){
    
#    print FH "$k->\n";
#    foreach $ele(@{$genome_cnm{$k}}){
#	print FH "$ele\n";
#    }
   
#    print FH "############\n";
#}
#close(FH);


sub generic_query (@) {

    my $query = $_[0];
    my $sqlQuery;
    my $rv;
    my $ctr;
    my @ret_array;
    my @ret;

    $sqlQuery = $dbh->prepare($query) or
        die "Can’t prepare $query: $dbh->errstrn";
    $rv = $sqlQuery->execute or
        die "can’t execute the query: $sqlQuery->errstr";
    $ctr = 0;

    while( @ret = $sqlQuery->fetchrow_array()){
        @{$ret_array[$ctr]} = @ret;
        $ctr ++;
    }

    return @ret_array;

}

sub oneliner (@) {
    my $query = $_[0];
    my $sqlQuery;
    my $rv;
    my $ctr;
    my @ret_array;
    my @ret;
    my @err = ();
    if($sqlQuery = $dbh->prepare($query)){}
    else{
        push(@err,0);
	push(@err,"Can’t prepare $query: $dbh->errstrn");
	return @err;
    }
    if($rv = $sqlQuery->execute){}
    else{
        push(@err,0);
        push(@err,"can’t execute the query: $sqlQuery->errstr");
	return @err;
    }
    $ctr = 0;

    while( @ret = $sqlQuery->fetchrow_array()){
        $ctr ++;
        if( $ctr > 1 ){
            push (@err,0); 
	    push(@err, "Error: unexpectedly\n$query\nreturns multiple lines\n");
	    mailme("Specs","Error: unexpectedly\n$query\nreturns multiple lines\n");
	    return @err;
	 }
        @ret_array = @ret;
    }

    return @ret_array;
}

############
sub formatted_sequence ( @) {

    my $ctr,
    my $sequence = $_[0];
    ( defined $sequence) ||
       return 0; 
    $ctr = 50;
    while ( $ctr < length $sequence ) {
        substr ($sequence, $ctr, 0) = "\n";
        $ctr += 51;
    }

    return $sequence;
}


sub hash_dictionary(@){
    ($dict_file, $dict) = @_;
    print "$dict_file\n";
    open(IF, "<$dict_file") || return "Cno $dict_file:$!\n";
    while(<IF>){
	chomp;
	next if(/^$/);
	@tmp=split;
	${$dict}{$tmp[2]}=$tmp[1];     
    }
    close(IF);
    
    return 0;
}

sub getCommonNm(@){
    ($shortnm, $dict_ref, $genomenm)=@_;
    $genome_with_commNm = 0;

    foreach $k(keys %{$dict_ref}){
	if($shortnm =~ /^($k)/){
	    $genome_with_commNm = $genomenm . "(".
		${$dict_ref}{$k} . ")";
	    last;
	}
    }
    return $genome_with_commNm;
}
