#! /usr/bin/perl -w
use IO::Handle;         #autoflush

defined $ARGV[0] || 
    die "usage: retrieve.pl <name_list>\n";

$HOME = "/home/i/imihalek";

$evalue =  1.e-5;
$database = "/home/pine/databases/nr";
$blast   = "$HOME/bin/blast/blastall";
$fastacmd = "$HOME/bin/blast/fastacmd";

$home = `pwd`;
chomp $home;


open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

while ( <NAMES> ) { 

    @aux = split;
    $name = $aux[0];
    $name =~ s/\s//g;

    $query     = "$name.seq";
    $blastout  = "$name.blastp";
    $gifile    = "$name.gi";
    $fastafile = "$name.fasta";
  

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
	next;
    } else {
	#$query_max = $#aux;
    }

    #blast -> returning gi's
    print "\t running blast ... \n"; 
    print "\t               writing to $blastout \n"; 
    $commandline = "$blast -p blastp -d $database -i $query -o $blastout -e $evalue  -v  400   -b  400 -K 500   -m 9";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("blast");
	next;
    }
    print "\t               ... done \n"; 

    # make plain list of gi's
    print "\t making list of gi's ... \n"; 
    open ( GI, ">$gifile") ||
        die "cno $gifile: $! \n";

    open ( BO, "<$blastout") ||
        die "cno $blastout: $! \n";
    %data = ();
    $gi_ctr = 0;
    while (<BO>) {
	next if ( /^\#/ );
	next if ( !/\S/ );
	@aux = split ('\|');
	if ( ! defined $data{$aux[1]} ) {
	    chomp;
	    $data{$aux[1]} = $_;
	    print GI " $aux[1] \n";
	    GI -> autoflush (1);
	    $gi_ctr++;
	}
    }
    
    close BO;
    close GI;
    print "\t               ... done \n";  
    


    # extract seq's from the database  by gi
    print "\t extracting sequences ... \n"; 
    if ( -e "$fastafile.tmp" ) {
	`rm $fastafile.tmp`;
    }
    $commandline = "$fastacmd -d $database -p T -t T  -i $gifile > $fastafile.tmp";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("fastacmd");
	next;
    }
    print "\t                  ... done\n"; 


}
