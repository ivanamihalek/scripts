#!/usr/gnu/bin/perl -w
# Ivana, Oct 2001
# for all the pdb files passed from
# stdin descend to the directory with the
# same root name and execute StatReports
# - the file  GlobalForRho4-$i.traceReportSummary 
# must be present
$STATFILENAME = "statsignf";

open ( STATFILE,">$STATFILENAME") 
    || die "could not open $STATFILENAME\n";
print STATFILE  "\n LCSg = LargestClusterSizeWithGap\n";
print STATFILE  " LCSw = LargestClusterSizeWithoutGap\n";
print STATFILE  " NCg  = NumOfClusterWithGap\n";
print STATFILE  " NCw  = NumOfClusterWithOutGap\n";
print STATFILE  "format: <largest cluster size> <max no residues> <<rank> <no clusters> <significance>>*\n\n";

while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	@aux = split ('\.', $fileName);
	pop @aux; # get rid of the pdb extension
	$nameroot = join ('.',@aux) ;


	print STATFILE  "     $nameroot      \n";

	$i = $nameroot;

	chdir ($nameroot ) ||
	    die "cannot chdir to $nameroot\n";
        $catch1 = `GenerateStatReportForLargestClusterSizeWithGap.pl GlobalForRho4-$i.traceReportSummary`;
        $catch2 = `GenerateStatReportForLargestClusterSizeWithoutGap.pl nogap/GlobalForRho4-$i.traceReportSummary`;
        $catch3 = `GenerateStatReportForNumOfClusterWithGap.pl GlobalForRho4-$i.traceReportSummary`;
        $catch4 = `GenerateStatReportForNumOfClusterWithoutGap.pl nogap/GlobalForRho4-$i.traceReportSummary`;
	chdir (".." ) ||
	    die "cannot chdir to .. \n";

	print STATFILE  " LCSg: ", $catch1; 
	print STATFILE  " LCSw: ", $catch2; 
	print STATFILE  "  NCg: ", $catch3; 
	print STATFILE  "  NCw: ", $catch4; 
	print STATFILE  "      ***********     \n\n";
	
    }
}

close STATFILE;
