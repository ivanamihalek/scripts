#!/usr/gnu/bin/perl -w
# Ivana, Oct 2001
# select only the lines  starting with "ATOM" from a pdb file
# the pdb files ar given as a list; the list is supposed to
# contain the names of the files; the files themselves 
# should be in the pdbfiles directory; the "stripped" files
# are saved to atoms directory
while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	$outfile = lc $fileName;
	if ( ! open ( INFILE, "<pdbfiles/$fileName") ) {
	    die "cannot open $fileName file\n" ;
	} else {
	    print " reading $fileName \n" ;
	}
	#if ( ! open ( OUTFILE, ">atoms/$outfile") ) {
	#    die "cannot open $outfile file\n" ;
	#} else {
	#    print "writing to  $outfile \n" ;
	#}
	while ( defined($line1 = <INFILE>) ) {
	    if ($line1=~ /ATOM(\s)+(\d)+(\s)+(\w)+(\s)+(\D){3}(\s)+/ ) { #&& ! ($line1 =~ /HETERO/)  ){
		print  $line1;
		#print OUTFILE $line1;
	    }
	}
	close INFILE;
       # close OUTFILE; 
    }
}
