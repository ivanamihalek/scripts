#!/usr/bin/perl -I/usr/local/lib/perl5/site_perl/5.8.0/sun4-solaris/DBI/
###############################################################################
#Date: 23 Oct. 2007                                                           #
#Script: getOrthologues.pl                                                    #
#Author:Zhang Zong Hong                                                       #
#Purpose: extract orthologues from database, ensembl installed on localhost   #
#Usage: perl getOrthologues.pl geneListFileName                               # 
###############################################################################


use DBI;

sub generic_query (@);
sub oneliner (@);
sub formatted_sequence ( @);
sub hash_dictionary(@);
sub getCommonNm(@); 

$numArgs = $#ARGV;

if($numArgs < 0){
    print "Usage: getOrthologus Gene_name(for gene names)\n";
    exit(1);  
}
open(FHANDLE,"<$ARGV[0]")|| die("Could not open file!");
@geneNlist = <FHANDLE>;
close(FHANDLE); 

$dictionary = "/home/zhangzh/speciesName";
$db_info = "DBI:mysql:database=ensembl:host=localhost";
$db_usr = "";
$db_pswd = "";
%dictionary = ();

($errmg)= hash_dictionary($dictionary, \%dictionary);
if($errmg){
    die "error on hash_dictionary subroutine:$errmg\n";
}

$dbh = DBI->connect($db_info, $db_use, $db_pswd, {RaiseError=>1,PrintError=>1});

foreach(@geneNlist){
    $geneN = $_;
    chomp($geneN);
    if(-e $geneN){$cmd = "rm -r $geneN"; system($cmd);}
    mkdir($geneN,0777) || die "can not mkdir $geneN: $!";
    $fastaFN= $geneN . ".fasta";
    $fastafile = "./$geneN/" . $fastaFN;
    
    open(FILEH, ">$fastafile");

    
    $query = "SELECT names, stable_id FROM gene_names ";
    $query .= "WHERE names LIKE '$geneN|%' or names LIKE '%|$geneN|%' or names LIKE '%|$geneN'";
    ($gname, $gid) = oneliner ($query);
    

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
    ($format_sequence) = formatted_sequence($sequence);
    %genome_cnm = ();
    if($format_sequence){
	#print ">$geneN\n$format_sequence\n";  
	print FILEH ">HOM_SAP_$geneN\n$format_sequence\n";
	foreach $array_ptr(@ortholog_gstable_idgroup){
	    ($gene_stable_id, $gene_pep_member_id, $or_gene_stable_id, $or_pep_member_id, $desc, $genome_name,$g_cnm,$g_groupid)=@{$array_ptr};
	    $query = "SELECT s.sequence,s.sequence_id from member m, sequence s ";
	    $query .= "WHERE m.member_id = '$or_pep_member_id' ";
	    $query .= "AND s.sequence_id = m.sequence_id";
	    ($or_sequence,$sq_id) = oneliner($query);
	    ($format_or_sequence) = formatted_sequence($or_sequence);
	    @aux = split " ", $genome_name;
	    $new_name = join "_", (uc  substr ($aux[0], 0, 3), 
				   uc  substr ($aux[1], 0, 3), $geneN);
                
	    #$genome_name_comm = getCommonNm($new_name,\%dictionary,$genome_name);
	   
	    push(@{$genome_cnm{$g_groupid}},"$new_name\t$or_gene_stable_id\t$genome_name($g_cnm)");
	   
	    
	    #if(!$genome_name_comm){
		#print "$new_name\t$or_gene_stable_id\t$genome_name\n";
	    #}
	    #else{
		#print "$new_name\t$or_gene_stable_id\t$genome_name_comm\n";
	    #}
	    print FILEH  ">$new_name\n$format_or_sequence\n";
		
 
	}  
        #print "\n\n\n####################\n";
        close(FILEH);
	print "name $geneN\n";
        foreach $genome(sort keys %genome_cnm){
            print "$genome->\n";
            foreach $ele(@{$genome_cnm{$genome}}){
                print "$ele\n";
            }
        }

    }
    else{
	print "$geneN sequence is not found\n";	
    
    }

}

$dbh->disconnect;
foreach $k(sort keys %genome_cnm){
    print "$k->\n";
    foreach $ele(@{$genome_cnm{$k}}){
	print "$ele\n";
    }
   
    print "############\n";
}

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

    $sqlQuery = $dbh->prepare($query) or
        die "Can’t prepare $query: $dbh->errstrn";
    $rv = $sqlQuery->execute or
        die "can’t execute the query: $sqlQuery->errstr";
    $ctr = 0;

    while( @ret = $sqlQuery->fetchrow_array()){
        $ctr ++;
        ( $ctr > 1 ) &&
            die "Error: unexpectedly\n$query\nreturns multiple lines\n";
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
