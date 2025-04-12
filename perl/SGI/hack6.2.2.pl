#!/usr/gnu/bin/perl -w
# Ivana, Oct 2001
# for all the pdb files passed from
# stdin descend to the directory with the
# same root name and execute StatReports
# - the file  GlobalForRho4-$i.traceReportSummary 
# must be present
# difce from hack6.pl: no pdb extension; get rid of nogap case
$STATFILENAME = "statsignf";

open ( STATFILE,">$STATFILENAME") 
    || die "could not open $STATFILENAME\n";
print STATFILE  "\n LCSg = LargestClusterSizeWithGap\n";
print STATFILE  " NCg  = NumOfClustersWithGap\n";
print STATFILE  "format: <largest cluster size> <max no residues> <<rank> <no clusters> <significance>>*\n\n";

while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	$nameroot = $fileName;
 
	print "working on    $nameroot ....      \n";
	print STATFILE  " $nameroot \n";
	$i = $nameroot;

	chdir ($nameroot ) ||
	    die "cannot chdir to $nameroot\n";
        $catch1 = `GenerateStatReportForLargestClusterSizeWithGap.pl GlobalForRho4-$i.traceReportSummary`;
	$catch3 = `GenerateStatReportForNumOfClusterWithGap.pl GlobalForRho4-$i.traceReportSummary`;
	chdir (".." ) ||
	    die "cannot chdir to .. \n";

	print STATFILE  " LCSg: ", $catch1; 
	print STATFILE  "  NCg: ", $catch3; 
	print STATFILE  "      ***********     \n\n";
		print "       $nameroot done      \n";

    }
}

close STATFILE;
