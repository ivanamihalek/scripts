#!/usr/bin/perl -w

use lib ("/sw/lib/perl5/5.8.1");
use DBI;

$database="ETdbFS";
$user="";
$password="";
$dbh = DBI->connect("DBI:mysql:$database", $user, $password);

$query = "SELECT COUNT(*) FROM trace WHERE project_id=\"LSET-7.22.03\" and bestzscore>=4;";
print "QUERY:\n$query\n\n";
print "RESULTS:\n";
$sth=preparequery($query);
while(@row = $sth->fetchrow_array)
{
	foreach $row (@row)
	{
		print "$row\n";
	}
}
$rc=$sth->finish;

$query = "SELECT traceresidue.variability FROM trace,tracerank,traceresidue WHERE tracerank.trace_id=trace.trace_id AND traceresidue.trace_id=trace.trace_id AND traceresidue.rank_id=tracerank.rank_id AND trace.project_id=\"LSET-7.22.03\" AND trace.bestzscore>4";
$addquery = " AND tracerank.coverage<=0.05";
DoQuery($query, $addquery, "Overall");

print `cat ~/dk131363/blosum/blosum62.matrixint`;
print "\n";

$query = "SELECT traceresidue.variability FROM trace,tracerank,traceresidue,structureresidue WHERE tracerank.trace_id=trace.trace_id AND traceresidue.trace_id=trace.trace_id AND traceresidue.rank_id=tracerank.rank_id AND trace.project_id=\"LSET-7.22.03\" AND trace.bestzscore>4 AND structureresidue.pdb_id=trace.pdb_id AND traceresidue.residuenumber=structureresidue.residuenumber AND structureresidue.solvacc>=20";
$addquery = " AND tracerank.coverage<=0.05";
DoQuery($query, $addquery, "Surface");

$query = "SELECT traceresidue.variability FROM trace,tracerank,traceresidue,structureresidue WHERE tracerank.trace_id=trace.trace_id AND traceresidue.trace_id=trace.trace_id AND traceresidue.rank_id=tracerank.rank_id AND trace.project_id=\"LSET-7.22.03\" AND trace.bestzscore>4 AND structureresidue.pdb_id=trace.pdb_id AND traceresidue.residuenumber=structureresidue.residuenumber AND structureresidue.solvacc<=2";
$addquery = " AND tracerank.coverage<=0.05";
DoQuery($query, $addquery, "Buried");

$query = "SELECT traceresidue.variability FROM trace,tracerank,traceresidue,structureresidue WHERE tracerank.trace_id=trace.trace_id AND traceresidue.trace_id=trace.trace_id AND traceresidue.rank_id=tracerank.rank_id AND trace.project_id=\"LSET-7.22.03\" AND trace.bestzscore>4 AND structureresidue.pdb_id=trace.pdb_id AND traceresidue.residuenumber=structureresidue.residuenumber AND structureresidue.secstruct=\"H\"";
$addquery = " AND tracerank.coverage<=0.05";
DoQuery($query, $addquery, "Helix");

$query = "SELECT traceresidue.variability FROM trace,tracerank,traceresidue,structureresidue WHERE tracerank.trace_id=trace.trace_id AND traceresidue.trace_id=trace.trace_id AND traceresidue.rank_id=tracerank.rank_id AND trace.project_id=\"LSET-7.22.03\" AND trace.bestzscore>4 AND structureresidue.pdb_id=trace.pdb_id AND traceresidue.residuenumber=structureresidue.residuenumber AND structureresidue.secstruct=\"E\"";
$addquery = " AND tracerank.coverage<=0.05";
DoQuery($query, $addquery, "Sheet");

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


sub DoOneQuery
{
	my $query=shift;
	my @array;
	my $aa;
	my $freq;
	my %aafreq;
	my %aapairfreq;
	my $totaa;
	my $sth;
	my $rc;
	print "QUERY:\n$query\n\n";
	$sth=preparequery($query);
	while(@row = $sth->fetchrow_array)
	{
		foreach $_ (@row)
		{
			@array=split;
			for ($i=0; $i<=$#array; $i++)
			{
				$array[$i]=~/(\d+)-(\D)/ or warn "Error!  $array[$i] was not expected!\n";
				$aa=$2;
				$freq=$1;
				$aafreq{$aa}+=$freq;
				$totaa+=$freq;
				$aapairfreq{$aa}{$aa}+=$freq*($freq-1)/2;
				for ($j=0; $j<$i; $j++)
				{
					$array[$j]=~/(\d+)-(\D)/ or warn "Error!  $array[$j] was not expected!\n";
					$aapairfreq{$aa}{$2}+=$freq*$1;
					$aapairfreq{$2}{$aa}+=$freq*$1;
				}
			}
		}
	}
	$rc=$sth->finish;
	return (\%aafreq, \%aapairfreq, $totaa);
}


sub DoQuery
{
	my $query=shift;
	my $addquery=shift;
	my $label=shift;
	my $query1=$query . ";";
	my $query2=$query . $addquery . ";";

	print "\n---------------------------------\n";
	print "$label";
	print "\n---------------------------------\n\n";

	my ($allaafreq, $allaapairfreq, $alltotaa) = DoOneQuery($query1);
	my ($impaafreq, $impaapairfreq, $imptotaa) = DoOneQuery($query2);
	my %allaafreq=%$allaafreq;
	my %allaapairfreq=%$allaapairfreq;
	my %impaafreq=%$impaafreq;
	my %impaapairfreq=%$impaapairfreq;

	$overallimptotaa=$imptotaa if $label eq "Overall";
	$overallalltotaa=$alltotaa if $label eq "Overall";

	Table(\%impaafreq, \%allaafreq, $imptotaa);

	print "\n";
	print "Proportion of $label residues : $label / All = ";
	printf ("%6.4f\n", $alltotaa/$overallalltotaa);
	print "Proportion of $label residues that are important : Important $label / All $label = ";
	printf ("%6.4f\n", $imptotaa/$alltotaa);
	print "Proportion of important residues that are $label : Important $label / All Important = ";
	printf ("%6.4f\n", $imptotaa/$overallimptotaa);
	print "\n";

	print "Important $label Residues\n";
	TransMatrix (\%impaapairfreq);

	print "All $label Residues\n";
	TransMatrix (\%allaapairfreq);
}


sub Table
{
	my $impaafreq=shift;
	my %impaafreq=%$impaafreq;
	my $allaafreq=shift;
	my %allaafreq=%$allaafreq;
	my $imptotaa=shift;
	@aaconv = ("A", "C", "D", "E", "F", "G", "H", "I", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "Y");
	@aaconv = sort { $allaafreq{$b} <=> $allaafreq{$a} } @aaconv;
	print "AA:\timpAA\tallAA\timpAA/allAA%\timpAA/impRes%\n";
	foreach $aa (@aaconv)
	{
		$impaafreq{$aa}=0 if !$impaafreq{$aa};
		$allaafreq{$aa}=0 if !$allaafreq{$aa};
		print "$aa\t$impaafreq{$aa}\t$allaafreq{$aa}\t";
		printf("%3.1f", 100*$impaafreq{$aa}/$allaafreq{$aa});
		print "%\t";
		printf("%3.1f", 100*$impaafreq{$aa}/$imptotaa);
		print "%\n";
	}
}


sub TransMatrix
{
	my $aapairfreq=shift;
	my %aapairfreq=%$aapairfreq;
	@aaconv = ("L", "A", "G", "V", "E", "S", "I", "K", "T", "D", "R", "P", "N", "F", "Q", "Y", "H", "M", "C", "W");
	my $sumfij=0;
	undef %pval;
	my $fij=0;
	my $fifj=0;
	my $oij=0;
	my $s=0;
	# calc matrix
	for ($aa1=0; $aa1<=$#aaconv; $aa1++)
	{
		for ($aa2=0; $aa2<=$#aaconv; $aa2++)
		{
			$fij[$aa1][$aa2]=$aapairfreq{$aaconv[$aa1]}{$aaconv[$aa2]};
			$sumfij+=$aapairfreq{$aaconv[$aa1]}{$aaconv[$aa2]};
		}
	}
	for ($i=0; $i<=$#aaconv; $i++)
	{
	        for ($j=0; $j<=$#aaconv; $j++)
	        {
	                if ($j==$i)
			{
				$pval[$j]+=$fij[$i][$j];
			}
	                else
			{
				$pval[$j]+=($fij[$i][$j]+$fij[$j][$i])/2;
			}
	        }
	}
	# print matrix
	foreach $aa (@aaconv) { print "   $aa"; }
	print "\n";
	for ($i=0; $i<=$#aaconv; $i++)
	{
		print "$aaconv[$i]";
		for ($j=0; $j<=$#aaconv; $j++)
	       	{
			if ($i==$j) { $fij = $fij[$i][$j]; }
			else { $fij=($fij[$i][$j]+$fij[$j][$i])/2; }
			$fifj=$pval[$i]*$pval[$j];
			if ($fifj > 0.000000001) { $oij = $sumfij * $fij / $fifj; }
			else { $oij = 0; }
			if ($oij > 0.000000001) { $s = log $oij; }
			else { $s=-20; }
			$s/=log(2);
	#		printf ("%8.4f ", $alls);
			printf ("%3.0f ", $s) if $j<=$i;
		}
		print "\n";
	}
	print "\n";
}
