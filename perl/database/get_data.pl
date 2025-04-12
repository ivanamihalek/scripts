#!/usr/bin/perl -w

use lib ("/sw/lib/perl5/5.8.1");
use DBI;

$database="ETdbFS";
$user="";
$password="";
$dbh = DBI->connect("DBI:mysql:$database", $user, $password);


print "\n---------------------------------\n\n";
$query = "SELECT traceresidue.residuetype, tracerank.coverage, traceresidue.variability ";
$query .= "FROM structure,alignment,trace,tracerank,traceresidue ";
$query .= "WHERE structure.pdb_id=trace.pdb_id AND alignment.alignment_id=trace.alignment_ID ";
$query .= "AND tracerank.trace_id=trace.trace_id AND traceresidue.trace_id=trace.trace_id ";
$query .= "AND tracerank.rank_id=traceresidue.rank_id AND trace.project_id='LSET-12.17.03' AND trace.bestzscore>4 ";
$query .= "AND alignment.numseq>30 AND structure.size>50 ";
#$query .= "AND traceresidue.variability REGEXP '^[^-]*-[^.]';";


=pod
To get important residues, do something like:

$cov=0.05;
$query = "SELECT tracerank.coverage,traceresidue.variability FROM structure,alignment,trace,tracerank,traceresidue WHERE structure.pdb_id=trace.pdb_id AND alignment.alignment_id=trace.alignment_ID AND tracerank.trace_id=trace.trace_id AND traceresidue.trace_id=trace.trace_id AND tracerank.rank_id=traceresidue.rank_id AND trace.project_id='LSET-12.17.03' AND trace.bestzscore>4 AND alignment.numseq>30 AND structure.size>50 AND traceresidue.variability REGEXP '^[^-]*-[^.]' AND tracerank.coverage<$cov;";

or, the query returns %coverage along with the alignment info, so it can be used to bin the alignment columns according to coverage
=cut



print "QUERY:\n$query\n\n";
$sth=preparequery($query);

@aas = (".", "A", "C", "D", "E", "F", "G", "H", "I", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "Y");
while(@row = $sth->fetchrow_array)
{

    foreach $type ( @aas ) {
        $perc{$type} = 0.0;
    }
    $total = 0;
    $restype = shift @row;
    $cvg     = shift @row;
    @aux = split ' ', (shift @row);
    for $str (@aux) {
        ($num, $type) = split '\-', $str;
        $perc{$type} = $num;
        $total += $num;
    }
    print "res: $restype   cvg: $cvg    ";
    foreach $type ( @aas ) {
        $perc{$type} /= $total;
        printf " %s:%6.3lf ", $type, $perc{$type};
    }
    print "\n";

}
$rc=$sth->finish;



$rc=$dbh->disconnect;

exit;

sub preparequery
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
