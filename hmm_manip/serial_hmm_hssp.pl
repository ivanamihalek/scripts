#! /usr/bin/perl -w

defined $ARGV[0] ||
    die "usage: serial_hmm_hssp.pl <name_list>\n";

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

open (FAIL, ">hmm_failures") ||
     die "cno hmm_failures: $!\n";
   

$home = `pwd`;
chomp $home;
$hmmdir = "/home/protean2/current_version/bin/linux";
$database = "/home/pine/databases/nr";
$extract_names = "/home/i/imihalek/perlscr/extractions/extr_gi_from_hmm.pl";
$fastacmd = "/home/i/imihalek/bin/blast/fastacmd";
$names_shorten = "/home/i/imihalek/perlscr/fasta_manip/fasta_names_shorten.pl";
$hmm2msf = "/home/i/imihalek/perlscr/translation/hmm2msf.pl";
$sift = "/home/i/imihalek/perlscr/filters/restrict_msf_to_query.pl";

while ( <NAMES> ) {
    next if ( !/\S/);

    $begin = time;
    chomp;
    @aux = split;
    $name = $aux[0];
    print "\n$name:\n";
    chdir $home ||
        die "cn chdir $home: $!\n";
    $dir = (substr $name, 0, 4)."/".$name;
    chdir $dir || next;

    $hssp_almt = "$name.hssp.msf";

    # check for the existence of the hssp alignment
    if  (!  -e $hssp_almt)  {
	print FAIL "$hssp_almt not found.\n";
	next;
    }
    # create hmm profile from hssp
    if ( ! -e  "hssp.hmm" ) {
	$cmd = "$hmmdir/hmmbuild hssp.hmm $hssp_almt";
	( system ($cmd) ) && die "hmmbuild failure\n";
	# calibrate the profile
	$cmd = "$hmmdir/hmmcalibrate hssp.hmm";
	( system ($cmd) ) && die "hmmcalibrate failure\n";
    }
    print "\t profile ok.\n";

    # search database using hmm 
    if ( ! -e  "hssp.hmmout" ) {
	$cmd = "$hmmdir/hmmsearch hssp.hmm $database > hssp.hmmout";
	( system ($cmd) ) && die "hmmsearch failure\n";
    }
    print "\t database search  ok.\n";

    if ( ! -e  "hssp.hmm.fasta" ) {
	# extract names from hsssp 
	$cmd = "$extract_names < hssp.hmmout > hssp.hmm.gi";
	( system ($cmd) ) && die " failure extracting names from hssp.hmmout\n";
	print "\t\t names ok.\n";

	# extract fasta with these names
	$cmd = "$fastacmd -i hssp.hmm.gi -d $database > hssp.hmm.fasta";
	( system ($cmd) ) && die " failure extracting fasta  from $database\n";
	print "\t\t extraction ok.\n";

	# shorten the fasta names 
	$cmd = "$names_shorten < hssp.hmm.fasta > tmp";
	( system ($cmd) ) && die " failure shortening names\n";
	`mv tmp  hssp.hmm.fasta`;
	print "\t\t names shortening ok.\n";

	# add the query
	$cmd = "cat $name.seq >>  hssp.hmm.fasta ";
	( system ($cmd) ) && die " failure adding  $name to hssp.hmm.fasta\n";

    }
    print "\t fasta ok.\n";
    

    # align using hmm 
    if ( ! -e  "hssp.hmmalign" ) {
	$cmd = "$hmmdir/hmmalign hssp.hmm hssp.hmm.fasta > hssp.hmmalign";
	( system ($cmd) ) && die "hmmalign failure\n";
    }
    print "\t hmmalignment ok.\n";

    # turn the alignment to msf format 
    if ( ! -e  "hssp.hmmm.msf" ) {
	$cmd = "$hmm2msf <  hssp.hmmalign > hssp.hmm.msf";
	( system ($cmd) ) && die "hmm2msf failure\n";
    }
    print "\t hmm2msf ok.\n";
  
    # restrict to query:
    if ( ! -e  "hssp.hmm.sifted.msf" ) {
	$cmd = "$sift hssp.hmm.msf $name";
	( system ($cmd) ) && die "sifting failure\n";
    }
    print "\t sifting ok.\n";
    
    print "\t                  ... done (", time-$begin, "s)\n";


}


close FAIL;
