#! /usr/bin/perl -w
use DBI;

# da li da hardcodiramo path do databaze?

( @ARGV >= 1 )  || die "Usage: $0  <db_name>.\n"; 

($dbname) = @ARGV;

($dbh = DBI->connect("DBI:mysql:$dbname", "root", "")) ||
 die "Cannot connect to $dbname.\n";

#########################################################################
$query = "SELECT DATABASE();";
#########################################################################
one_line_query ();

print "##############################\n";
$query = "SHOW TABLES;";
print $query."\n";

$sth = prepare_and_exec( $query);
@tables = ();

while(@row = $sth->fetchrow_array) {
    push @tables, @row;
}
$rc=$sth->finish;

foreach $table (@tables) {

    print "$table\n";
    $query = "SHOW COLUMNS FROM $table;";
    one_line_query ();


}



=pod
#search in database
print "##############################\n";
$query = "SELECT sequence FROM protein ".
    "WHERE ensembl_id='$protid'";

print $query."\n";

$sth= prepare_and_exec( $query);
$ctr = 0;
while(@row = $sth->fetchrow_array) {

    foreach $row (@row) {
        print " $row ";
    }
    print "\n";
}
$rc=$sth->finish;

print "##############################\n";
$query = "SELECT ensembl_id FROM exon ".
    " WHERE ref_protein_id='$protid'  ".
    " AND species='$species'  ".
    " AND source='sw_gene'";


print $query."\n";

$sth= prepare_and_exec( $query);
$ctr = 0;
while(@row = $sth->fetchrow_array) {

    foreach $row (@row) {
        print " $row ";
    }
    print "\n";
}
$rc=$sth->finish;

print "##############################\n";
foreach $ref_exon_id ( @ref_exon_ids ) {

    $query = " SELECT * FROM best_exon_alignment  ".
	" WHERE ref_exon_id='$ref_exon_id' ";
    $sth= prepare_and_exec( $query);
    $ctr = 0;
    while(@row = $sth->fetchrow_array) {

	foreach $row (@row) {
	    print " $row ";
	}
	print "\n";
    }
    $rc=$sth->finish;
    print "          ##################\n";

    
}

=cut



$rc=$dbh->disconnect;

exit;


#untie the databse
#undef $db;
#untie %database;

sub prepare_and_exec
{
        my $query=shift;
        my $sth;
        my $rv;
        my $rc;
        $sth=$dbh->prepare($query);
        if (!$sth)
        {
               print "Can't prepare $query\n";
               $rc=$dbh->disconnect;
               exit;
        }
        #$sth->trace(2);
        $rv=$sth->execute;
        if (!$rv)
        {
               print "Can't execute $query\n";
               $rc=$dbh->disconnect;
               exit;
        }
        return $sth;
}



sub one_line_query {


    my $sth;
    my @row;
    my $row;

    print "\n*******************************************\n";
    print "QUERY:         $query\n";
    print "RESULTS:             \n";
    $sth= prepare_and_exec( $query);
    while(@row = $sth->fetchrow_array)
    {
	print "\t\t";
	foreach $element (@row)
        {
	    if ( defined $element ) {
		print "$element  ";
	    }
        }
	print "\n";
   }
    $rc=$sth->finish;

}
