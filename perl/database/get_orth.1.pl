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
sub get_and_print_seq (@);

$numArgs = $#ARGV;

if($numArgs < 0){
    print "Usage: getOrthologus Gene_name(for gene names)\n";
    exit(1);  
}
open(FHANDLE,"<$ARGV[0]")|| die("Could not open file!");
@geneNlist = <FHANDLE>;
close(FHANDLE); 

$db_info = "DBI:mysql:database=ensembl:host=localhost";
$db_usr = "";
$db_pswd = "";
$dbh = DBI->connect($db_info, $db_use, $db_pswd, {RaiseError=>1,PrintError=>1});

foreach(@geneNlist){
    $geneN = $_;
    chomp($geneN);

    $query = "SELECT names, stable_id FROM gene_names ";
    $query .= "WHERE names LIKE '$geneN|%' or names LIKE '%|$geneN|%'";
    ($gname, $gid) = oneliner ($query);

    ##retrieve gene_stable_id of orthologues
    $query = "SELECT m1.stable_id, hm1.peptide_member_id, ";
    $query .= " m2.stable_id, hm2.peptide_member_id, h.description, g.name ";
    $query .= "FROM member m1, member m2, homology_member hm1, homology_member hm2, "; 
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
        

    $first = 1;
    foreach $array_ptr(@ortholog_gstable_idgroup){
	($gene_stable_id, $gene_pep_member_id, $or_gene_stable_id, 
	 $or_pep_member_id, $desc, $genome_name) = @{$array_ptr};
	if ( $first ) {
	    $first = 0;
	    # note this !! I am assuming the query 
             # is human
	    get_and_print_seq ( $gene_pep_member_id, 'Homo sapiens' );
	}
	get_and_print_seq ( $or_pep_member_id, $genome_name );
    }  
}

$dbh->disconnect;

###################################
sub get_and_print_seq (@) {
    my $pep_id =  $_[0];
    my $genome_name =  $_[1];
    my ($query, $sequence, $new_name); 
    my @aux;

    $query = "SELECT s.sequence FROM  member m, sequence s ";
    $query .= "WHERE m.member_id = '$or_pep_member_id' ";
    $query .= "AND s.sequence_id = m.sequence_id";
    ($sequence) = oneliner($query);
    @aux = split " ", $genome_name;
    $new_name = join "_", (uc  substr ($aux[0], 0, 3), 
			       uc  substr ($aux[1], 0, 3), $geneN);
    print "> $new_name\n", formatted_sequence($sequence), "\n";
}

###################################


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
        die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) {
        substr ($sequence, $ctr, 0) = "\n";
        $ctr += 51;
    }

    return $sequence;
}

