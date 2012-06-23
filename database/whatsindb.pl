#!/usr/bin/perl -w

use lib ("/usr/lib/perl5/5.8.1");
use DBI;

$database="human_genome";
$user="";
$password="";
$dbh = DBI->connect("DBI:mysql:$database", $user, $password);

#########################################################################
$query = "SELECT DATABASE();";
#########################################################################
one_line_query ();

$query = "SHOW TABLES;";
one_line_query ();

$sth= prepare_and_exec( $query);

while(@row = $sth->fetchrow_array) {

    foreach $row (@row) {

        chomp $row;
        $query = "DESCRIBE $row;";
        one_line_query ();
   }
}
$rc=$sth->finish;





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
