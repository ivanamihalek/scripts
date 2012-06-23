#! /usr/bin/perl -w
use IO::Handle;         #autoflush

# pipeline    : from training msf to etc analysis usinh hmm database search
# input       : list of names (<name>s),  for which the script should be executed
# requirements:  (1) sequence file (<name>.seq) ---> dispensable, but the script needs to be hacked
#                (2) training msf file (<name>.training)
#                (3) pdb file (<name>.pdb)

defined $ARGV[0] || 
    die "usage: retrieve.pl <name_list>\n";

#$database = "/pine/databases/nr";
$database = "/pine/databases/custom";
#$blast    = "/home/protean5/imihalek/bin/blast/blastpgp";
$hmm_path = "/home/protean2/current_version/bin/linux";
$hmmbuild      = "$hmm_path/hmmbuild";
$hmmcalibrate  = "$hmm_path/hmmcalibrate";
$hmmsearch     = "$hmm_path/hmmsearch";

$hmmparse = "/home/i/imihalek/perlscr/hmmparse.pl"; # at this point have fasta

$hmmalign      = "/home/i/imihalek/hmmer-2.2g/binaries/hmmalign";
$remove_matching = "/home/i/imihalek/perlscr/remove_matching_fasta.pl";

$msf2fasta  = "/home/i/imihalek/perlscr/msf2fasta.pl";
$translate  = "/home/i/imihalek/perlscr/hmm2msf.pl";

$etc        = "/home/protean2/current_version/bin/linux/etc";
$color_by_cluster = "/home/i/imihalek/perlscr/cbc.pl";


open ( ERRLOG, ">errlog") ||
    die "Cno errlog:$! \n.";
 

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

$home = `pwd`;
chomp $home;

$nice_level = "-n +10";

while ( <NAMES> ) { 
   
    $begin = time;
    chomp;
    $name = $_;

    $query     = "$name.seq";
    $hmmout    = "$name.hmmsearch";
    $hmmalignment = "$name.hmm_align";
    $msffile    = "$name.hmm_msf";
    $pdbfile   = "$name.pdb";
    $epifile   = "$name.pdb_epitope";

    $hmm_model = "$name.hmm";
    $hmmtraining = "$name.training";

    print "\n $name:\n"; 

=pod
    chdir $home ||
	die "cn chdir $home: $!\n";
    chdir $name ||
	 die "cn chdir $name: $!; current dir is: ".`pwd`."\n";
=cut

    if ( ! -e $query ) {
	print "$query file not found.\n";
	next;
    }
    open ( QF, "<$query") ||
        die "cno $query: $! \n";
    <QF>;
    $original = "";
    while ( <QF>) {
	chomp;
	$original .= $_;
    } 
    close QF;
    @aux  = split '', $original;
    if ( $#aux  <= 30 ) {
	print "\toriginal seq too short (",$#aux+1,"). moving on.\n";
    	print ERRLOG "\n$name: original seq too short ($#aux).\n";
	next;
    } else {
	$query_max = $#aux;
    }


    #hmm
    print "\t hmmbuild ... \n"; 
    if ( -e $hmm_model ) {
	`rm $hmm_model`;
    }
    $commandline = "nice $nice_level $hmmbuild $hmm_model $hmmtraining";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("hmmbuild");
	next;
    }
    print "\t               ... done \n"; 

    print "\t hmmcalibrate ... \n"; 
    $commandline = "nice $nice_level $hmmcalibrate $hmm_model ";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("hmmcalibrate");
	next;
    }
    print "\t               ... done \n"; 

    print "\t hmmsearch ... \n"; 
    if ( -e $hmmout ) {
	`rm $hmmout`;
    }
    $commandline = "nice $nice_level $hmmsearch $hmm_model $database > $hmmout";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("hmmcalibrate");
	next;
    }
    print "\t               ... done \n"; 

    
    # parse hmm output
    print "\t parsing hmm output ... \n"; 
    $commandline = "nice $nice_level $hmmparse $name";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("hmmcalibrate");
	next;
    }
    print "\t               ... done \n"; 

    # collect all seqs make sure to tack the query seq to the top of this file
    print "\t collecting all ... \n"; 
    $commandline = "$msf2fasta $name.training";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("msf2fasta");
	next;
    }
    if ( -e "tmp.fasta" ) {
	`rm tmp.fasta`;
    }
    $commandline = "cat  $name.training.fasta $name.0.fasta > tmp.fasta";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("concatenation");
	next;
    }
    print "\t               ... done \n"; 
    

    # remove substrings from fasta
    print "\t removing  matching substrings from fasta ... \n"; 
    $commandline = "$remove_matching tmp";
    $retval   = system ($commandline);
    if ( $retval ) {
	printf "retval: $retval \n";
	process_failure("remove_matching_fasta");
	next;
    }
    print "\t                  ... done\n"; 


    # align
    print "\t hmmalign ... \n"; 
    if ( -e $hmmalignment ) {
	`rm $hmmalignment`;
    }
    $commandline = "nice $nice_level $hmmalign $hmm_model tmp.fasta > $hmmalignment";
    $retval   = system ($commandline);
    if ( $retval) { 
	printf "retval: $retval \n";
	process_failure("clustalw");
	next;
    }
    print "\t                  ... done\n"; 

    # clean up the msf format
    print "\t clean up the msf format ... \n"; 
    if ( -e $msffile ) {
	`rm $msffile`;
    }
    $commandline = "nice $nice_level $translate < $hmmalignment > $msffile";
    $retval   = system ($commandline);
    if ( $retval ) {
	printf "retval: $retval \n";
	process_failure("clustalw");
	next;
    }
    print "\t                  ... done\n"; 


    # trace
    $logname = "$outname.log";

    print "\t running trace ... \n"; 
    if ( -e $logname) {
	`rm $logname`;
    }

    $outname = "$name";
    $commandline = "nice $nice_level $etc -p $msffile -o $outname  -prune 31  -x $name $name.pdb -c  ";
    if ( -e $epifile ) {
	$commandline .= " -epitope $epifile";
    }
    print "\t $commandline \n";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("trace");
	next;
    }

    $outname = "$name.entr";
    $msffile = "$name.pruned.msf";
    $commandline = "nice $nice_level $etc -p $msffile -o $outname -entropy  -x $name $name.pdb -c  ";
    if ( -e $epifile ) {
	$commandline .= " -epitope $epifile";
    }
    print "\t $commandline \n";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("trace");
	next;
    }

    $outname = "$name.new";
    $msffile = "$name.pruned.msf";
    $commandline = "nice  $nice_level $etc -p $msffile -o $outname -realval   -x $name $name.pdb -c  ";
    if ( -e $epifile ) {
	$commandline .= " -epitope $epifile";
    }
    print "\t $commandline \n";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("trace");
	next;
    }

    print "\t                  ... done (", time-$begin, "s)\n"; 
    next; # <<+++++++++++++++

=pod
    #color-by-cluster
    print "\t color-by-cluster ... \n"; 
    $commandline = " $color_by_cluster $outname.clusters $name.pdb ";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("cbc");
	next;
    }
=cut
}

close ERRLOG;

