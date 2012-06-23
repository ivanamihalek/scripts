#!/usr/bin/perl -w
#note: the database is on cedar
use lib ("/sw/lib/perl5/5.8.1");
use DBI;

$database="ETdbFS";
$user="";
$password="";
$dbh = DBI->connect("DBI:mysql:$database", $user, $password);

#########################################################################
$query = "SELECT DATABASE();";
#########################################################################
one_line_query ();

$query = "SHOW TABLES;";
one_line_query ();

$pdb = "'3ulla'";

$query  = "SELECT trace_id  FROM trace  WHERE PDB_ID=$pdb";

$sth= prepare_and_exec( $query);
while(@row = $sth->fetchrow_array) {

    foreach $row (@row) {
        $name = "'$row'";
   }
}
$rc=$sth->finish;




$query  = "SELECT  traceresidue.residuenumber, traceresidue.rank_ID, neighborresiduenumber, distance   ";
$query .= "FROM  traceresidue, structureneighbor ";
$query .= "WHERE  traceresidue.Trace_ID=$name AND structureneighbor.PDB_ID=$pdb ";
$query .= "AND structureneighbor.distance < 5.0";

$sth= prepare_and_exec( $query);
$ctr = 0;
while(@row = $sth->fetchrow_array) {

    foreach $row (@row) {
        print " $row ";
   }
    print "\n";
}
$rc=$sth->finish;



$query = "SELECT COUNT(*)  FROM trace;";
one_line_query ();


$rc=$dbh->disconnect;

exit;


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

    print "\n*******************************************\nQUERY:\n$query\n\n";
    print "RESULTS:\n";
    $sth= prepare_and_exec( $query);


=pod
    while(@row = $sth->fetchrow_array)
    {
        foreach $row (@row)
        {
            print "$row\n";
        }
    }
=cut

        $sth->dump_results();
        $rc=$sth->finish;
}
