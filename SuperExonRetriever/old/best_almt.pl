#! /usr/bin/perl -w
use DBI;

sub find_ensembl_exons (@);
sub find_sw_pieces (@);
sub find_gene_location (@);
sub find_ref_exon_ids  (@);
sub find_ref_exons      ();
sub find_ref_sequence  (@);
sub find_species_w_orthologues (@);

sub formatted_sequence (@);

# da li da hardcodiramo path do databaze? it ak je login hardkodiran ...

#( @ARGV >= 2 )  || die "Usage: $0  <db_name> <protein id> <species> <outfile>.\n"; 
#($dbname, $protid, $qry_species, $outname) =   @ARGV; 

$dbname = "exolocator_db";

$protid = "";
( @ARGV ) && ($protid = $ARGV[0]);


($dbh = DBI->connect("DBI:mysql:$dbname", "marioot", "tooiram")) ||
    die "Cannot connect to $dbname.\n";

@prot_ids = ();
if ( $protid ) {
    @prot_ids = ( $protid );
} else {

    @prot_ids = ();

    $query = "SELECT ref_protein_id FROM gene WHERE species = 'Homo_sapiens'";
    $sth= prepare_and_exec( $query);
    while(@row = $sth->fetchrow_array) {
	push @prot_ids, @row;

    }

}

#print "number of reference protein ids: ", scalar @prot_ids, " \n";
#exit;

$enough = 0;
foreach $protid ( @prot_ids ) {

    ###############################################################
    # the reference human sequence
    $human_sequence = "" || find_ref_sequence ($protid);
    $human_sequence || die "NOTE no sequence found for $protid\n";

    #$orig_human_seq_lenth = length($human_sequence);
    #$all_gaps = "-" x $orig_human_seq_lenth;

    ################################################################
    # the reference  exon ids
    @ref_exon_ids   = ();
    find_ref_exon_ids ($protid);
    (@ref_exon_ids)     || die "NOTE no ref exon ids found for $protid\n";

    ################################################################
    # the reference  exon ids
    %ref_exon_seq = ();
    find_ref_exons ();
    (%ref_exon_seq )  || die "NOTE no ref exon seqeunces found for $protid\n";


    ###############################################################
    # all species for which we have found an ortholog
    @species_w_orthologues = ();
    find_species_w_orthologues  ($protid);
    (@species_w_orthologues)  || die "NOTE no species found for $protid\n";

    ###############################################################
    # for each species find the gene location according to Ensembl
    %gene_location = ();
    %ensembl_exons = ();
    foreach $species (@species_w_orthologues) {
	$gene_location{$species}    = find_gene_location ($protid, $species);
	@{$ensembl_exons{$species}} = find_ensembl_exons ($protid, $species);  
	@{$ensembl_exons{$species}} || die "no exons found in ensembl for $protid  $species\n";
    }



    ###############################################################
    # fore ach species find the pieces we found using 
    # each human exon as a bait 
    %sw_exons = ();
    foreach $species (@species_w_orthologues) {
	@{$sw_exons{$species}} = find_sw_pieces ($species);  
	@{$sw_exons{$species}} || print "no exons found by sw for $protid  $species\n";
    }

    print "###########################################\n";
    print "$protid\n";
    foreach $ref_exon_id (@ref_exon_ids) {
	print "\t $ref_exon_id $ref_exon_seq{$ref_exon_id} \n";
    }

    foreach $species (@species_w_orthologues) {

	($chrom_piece, $ens_from, $ens_to) =  split " ",  $gene_location{$species};

	($consensus_from, $consensus_to)  =  ($ens_from, $ens_to);

	foreach $piece (@{$sw_exons{$species}}) {
	    ($from, $to) = split " ", $piece;
	    if ( $from < $consensus_from) {
		$consensus_from = $from;
	    }
	    if ( $to > $consensus_to) {
		$consensus_to = $to;
	    }
	}
	printf " %-30s      $ens_from    $ens_to  ----  ".
	    " $consensus_from   $consensus_to    \n", $species ;
	if (  $consensus_to - $consensus_from  > 2*( $ens_to - $ens_from ) ) {


	    print join "\n\t", @{$ensembl_exons{$species}};
	    print "\n";
	    
	    printf "\n\tSWsharp gene pos: \n\t";
	    print join "\n\t", @{$sw_exons{$species}};
	    print "\n";
	    exit;

	}
	
    }


=pod
    print "###########################################\n";
    print "$protid\n";
    foreach $ref_exon_id (@ref_exon_ids) {
	print "\t $ref_exon_id $ref_exon_seq{$ref_exon_id} \n";
    }
    foreach $species (@species_w_orthologues) {
	printf "\n\t$species\n";
	printf "\n\tENSEMBL gene pos:  %-40s\n",  $gene_location{$species};
	printf "\t        exons:\n\t";

	print join "\n\t", @{$ensembl_exons{$species}};
	print "\n";
	    
	printf "\n\tSWsharp gene pos: \n\t";
	print join "\n\t", @{$sw_exons{$species}};
	print "\n";
    }
=cut

    $enough++;
    ($enough == 1) && exit;
} 


#untie the databse
$dbh->disconnect;


###############################################################
###############################################################
###############################################################
###############################################################
###############################################################
#
sub find_gene_location (@) {

    my ($protid, $species) = @_;
    my ($query, $sth, $rc);
    my ($loc_id, $start, $stop) = ();

    $query = "SELECT location_id, start, stop  FROM ortholog ".
	"WHERE  ref_protein_id ='$protid' ".
	" AND species='$species' ";

    $sth = prepare_and_exec( $query);
    ($loc_id, $start, $stop) = $sth->fetchrow_array;
    $rc  = $sth->finish;
    
    return "$loc_id  $start  $stop";
    
}
###############################################################
#
sub find_ensembl_exons (@) {

    my ($protid, $species) = @_;
    my ($query, $sth, $rc);
    my %aux  = ();
    my @exon = ();

    $query = "SELECT start, stop  FROM exon ".
	"WHERE ref_protein_id='$protid' AND species='$species' ";
    $sth= prepare_and_exec( $query);
    while ( ($start, $stop) = $sth->fetchrow_array ) {
	$aux{$start} = $stop;
    }
    my @sorted_start = sort {$a <=> $b} (keys %aux);

    foreach (@sorted_start) {
	push @exon, "$_  $aux{$_}";
    }


    return @exon;
}

###############################################################
#
sub find_sw_pieces (@)  {

    my ($species) = @_;
    my ($query, $sth, $rc);

    my $ref_exon_id;
    my %aux        = ();
    my @exon_piece = ();
   

    foreach $ref_exon_id (@ref_exon_ids) {

	$query = "SELECT  genome_start, genome_stop FROM exon_alignment_piece ".
	    "WHERE species='$species' AND ref_exon_id='$ref_exon_id' ";

	$sth= prepare_and_exec( $query);
	while ( ($start, $stop) = $sth->fetchrow_array ) {
	    $aux{$start} = $stop;
	}
    }

    my @sorted_start = sort {$a <=> $b} (keys %aux);

    foreach (@sorted_start) {
	push @exon_piece, "$_  $aux{$_}";
    }


    return @exon_piece;
}


###############################################################
#
sub find_ref_sequence (@) {

    my ($protid) = @_;
    my ($query, $sequence, $sth, $rc);

    $query = "SELECT sequence  FROM protein ".
	"WHERE ensembl_id='$protid' ";
    $sequence = "";
    $sth= prepare_and_exec( $query);
    ($sequence) = $sth->fetchrow_array;
    $rc=$sth->finish;

    return $sequence;
}

###############################################################
# 
sub find_ref_exon_ids (@) {

    my ($protid) = @_;
    my ($query, $sth, $rc);
    my ($ref_exon_id) = ();

    $query = "SELECT ensembl_id FROM exon ".
	"WHERE ref_protein_id='$protid' ".
	"AND species='Homo_sapiens' ".
	"AND source='ensembl'";

    $sth= prepare_and_exec( $query);
    while(  ($ref_exon_id)  = $sth->fetchrow_array) {
	push @ref_exon_ids, $ref_exon_id;
    }
    $rc=$sth->finish;


}

###############################################################
# 
sub find_ref_exons () {

    my ($query, $sth, $rc);
    my ($ref_exon_id, $ref_prot_start, $ref_prot_stop) = ();


    foreach $ref_exon_id (@ref_exon_ids) {

	$query = "SELECT  ref_prot_start, ref_prot_stop ".
	    "FROM exon_alignment_piece ".
	    "WHERE ref_exon_id='$ref_exon_id' ";

	$sth= prepare_and_exec( $query);

	while( ($ref_prot_start, $ref_prot_stop)  = $sth->fetchrow_array) {

	    $ref_exon_seq{$ref_exon_id} = substr $human_sequence,  
	    $ref_prot_start, $ref_prot_stop - $ref_prot_start + 1;	
	}
	$rc=$sth->finish;
    }


}




#mysqldump -uSOURCE_USERNAME -pSOURCE_PASSWORD --no-create-db SOURCE_DB_NAME \
# | mysql -uTARGET_USERNAME -pTARGET_PASSWORD TARGET_DB_NAME

###############################################################
# 
sub find_species_w_orthologues (@) {

    my ($protid) = @_;
    my ($query, $sequence, $sth, $rc);
    $query = "SELECT species FROM ortholog WHERE ref_protein_id = '$protid'";
    $sth= prepare_and_exec( $query);
    my %seen = ();
    while( ($species) = $sth->fetchrow_array) {

	next if ($species eq "Homo_sapiens");
	if ( ! defined $seen{$species} ) {
	    push @species_w_orthologues, $species;
	    $seen{$species} = 1;
	}
    }
}


=pod
#@some_info = ();
#@some_info = grep { /$qry_species/ } @species_w_exons_found;
#	
#if  ( ! @some_info ) {
#   die "NOTE no matching exons found for $protid in $qry_species.\n";
#   
#} 
    


#####################################################################
# SW# exons for the qry species

$ctr = 0;
@qry_exon_ids = ();
%qry_from = ();
%qry_to = ();
%belons_to = ();
foreach $ref_exon_id ( @ref_exon_ids ) {

    $query = "SELECT  genome_start, genome_stop FROM exon_alignment_piece ".
	"WHERE species='$qry_species' AND ref_exon_id='$ref_exon_id' ";

    $sth = prepare_and_exec($query);
    ($qry_exon_from, $qry_exon_to) = ();

    while(  ($qry_exon_from, $qry_exon_to)  = $sth->fetchrow_array ) {
	
	$ctr++;

	$qry_exon_id = "$qry_species\_sw$ctr";

	push @qry_exon_ids, $qry_exon_id;
	$qry_from{$qry_exon_id} = $qry_exon_from;
	$qry_to{$qry_exon_id}   = $qry_exon_to;
	$belongs_to{$qry_exon_id} = $ref_exon_id;
    }    
    $rc = $sth->finish;
}

print "\n";
foreach $qry_exon_id ( @qry_exon_ids ) {
    print "  $qry_exon_id    $qry_from{$qry_exon_id}   $qry_to{$qry_exon_id}  ".
	" $belongs_to{$qry_exon_id}\n";
}


#####################################################################
# the pieces that we have assembled using SW#
%outseq = ();
foreach $species ( 'Homo_sapiens', $qry_species ) {

    @name = split "_", $species;
    $initials = uc ( (substr $name[0], 0, 3).( substr $name[1], 0, 3) );

    #the exons from the queried species
    ($refseq, $specseq, $from, $to)  = ();
    foreach $ref_exon_id ( @ref_exon_ids ) {

	$query = " SELECT ref_protein_seq, spec_protein_seq, ref_prot_start, ref_prot_stop".
	    " FROM exon_alignment_piece   ".
	    " WHERE ref_exon_id='$ref_exon_id' ".
	    " AND species='$species' ";
	$sth= prepare_and_exec( $query);
 
	while( ($refseq, $specseq, $from, $to) = $sth->fetchrow_array) {

	    $length = $to - $from + 1;
	    ( $length < 4 ) && next;

	    $new_seq = $all_gaps;
	    (substr $new_seq, $from, $length) = $specseq;
	    $outseq{$species}{$from}  = ">$initials\_$from\n";
	    $outseq{$species}{$from} .= formatted_sequence($new_seq);
	    $outseq{$species}{$from} .= "\n";

	}
	$rc=$sth->finish;
    }
}

#####################################################################
# finally, output the whole thing;
open (OUT, ">$outname") || die "Cno $outname: $!.\n";

print  OUT ">HS_full\n";
print  OUT formatted_sequence($sequence);
print  OUT  "\n";


foreach $from (0 .. $orig_human_seq_lenth-1) {

    $species = 'Homo_sapiens';
    if ( defined $outseq{$species}{$from}) {
	print  OUT  $outseq{$species}{$from};
    }

    $species =  $qry_species;

    if ( defined    $outseq{$species}{$from}) {
	print  OUT  $outseq{$species}{$from};
    }
	
	
    
}

close OUT;




=cut


############################################################################3

sub prepare_and_exec {

    my $query=shift;
    my $sth;
    my $rv;
    my $rc;
    $sth=$dbh->prepare($query);

    if (!$sth) {
	print "Can't prepare $query\n";
	$rc=$dbh->disconnect;
	die;
    }
    #$sth->trace(2);

    $rv=$sth->execute;
    if (!$rv) {
	print "Can't execute $query\n";
	$rc=$dbh->disconnect;
	die;;
    }
    return $sth;
}


#############################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 
