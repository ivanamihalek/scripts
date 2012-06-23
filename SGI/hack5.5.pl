#!/usr/gnu/bin/perl -w
# Ivana, Nov 2001
# for all the pdb files passed from
# descend to the directory with the
# same root name; create directory called "nogap"
# and execute TracePlus6.01 without the -g option,
# followed by cluster counting and coloring
$LOGFILENAME = "statlog";


while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	@aux = split ('\.', $fileName);
	pop @aux; # get rid of the pdb extension
	$nameroot = join ('.',@aux) ;

	chdir ($nameroot ) ||
	    die "cannot chdir to $nameroot\n";
	open ( LOGFILE,">$LOGFILENAME") 
	    || die "could not open $LOGFILENAME\n";
	print LOGFILE $nameroot, "\n"; 

        if ( -e "nogap" ) {
	} else {
	    @cmmdarray = ('mkdir', "nogap");
	    system (@cmmdarray); 
	}
	chdir ("nogap" ) ||
	    die "`pwd`: cannot chdir to nogap\n";
        
	$i = $nameroot;
        @cmmdarray = ('cp', '-f', "../$i.msf",  "$i.msf"); 
	if ( system (@cmmdarray) ){
	    print `pwd`, ": could not exec $cmmdarray[0] \n"; 
	    die;
	}

       @cmmdarray = ('cp', '-f', "../pt_$i.pdb",  "."); 
	if ( system (@cmmdarray) ){
	    print `pwd`, ": could not exec $cmmdarray[0] \n"; 
	    die;
	}

        @cmmdarray = ('cp', '-f', "../pt_$i.access",  "."); 
	if ( system (@cmmdarray) ){
	    print `pwd`, ": could not exec $cmmdarray[0] \n"; 
	    die;
	}

       @cmmdarray = ("TracePlus6.01  -p  $i.msf  -o  ET_$i  -m  blosum62  -t   +profile -rs  -x  pt_$i  pt_$i.pdb  pt_$i.access" );
	print LOGFILE @cmmdarray, "\n"; 
	$time0 = time;
	system (@cmmdarray); 
	$time = time -$time0;
	print "TracePlus done (walltime: $time s). Running ClusterCounter: \n"; 
	print LOGFILE "TracePlus done (walltime: $time s). Running ClusterCounter: \n"; 

	@cmmdarray = ("java -classpath /home/concorde/hy131321/lset/classes trace.ClusterCounterForTrace pt_$i.pdb ET_$i.groups g 4 -$i");
	print LOGFILE @cmmdarray, "\n"; 
	$time0 = time;
	! system (@cmmdarray)
	    || die "Error execing $cmmdarray[0]"; 
	$time = time -$time0;
	print  "ClusterCounter done (walltime: $time s). Running ColorByCluster \n"; 
	print LOGFILE "ClusterCounter done (walltime: $time s). Running ColorByCluster \n"; 

	@cmmdarray = ("/home/concorde/dk131363/bin/ColorProteinByCluster.pl 2> /dev/null"); 
	print LOGFILE @cmmdarray, "\n"; 
	$time0 = time;
	! system (@cmmdarray)
	     || die "Error execing $cmmdarray[0]"; 
	$time = time -$time0;
	print  "ColorByCluster done  (walltime: $time s). \n\t ******** \n\n"; 
	print LOGFILE "ColorByCluster done  (walltime: $time s). \n\t ******** \n\n"; 
	close LOGFILE;
	chdir ("../.." ) ||
	    die "cannot chdir to ../..  \n";
	
    }
}

