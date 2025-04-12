#! /usr/bin/perl -w
use IO::Handle;         #autoflush

defined $ARGV[0] || 
    die "usage: retrieve.pl <name_list>\n";

$HOME = "/home/i/imihalek";

#$database = "/pine/databases/bacterial_genomes/bacterial_genomes.fasta";
#$$database = "/home/i/imihalek/projects/colab/ABC/membrane_spanning/ABC.fasta";
#$database = "/home/pine/databases/uniprot";
$database = "/home/pine/databases/nr";
#$database = "/pine/databases/custom";

#$blast    = "$HOME/bin/blast/blastpgp";
$blast   = "$HOME/bin/blast/blastall";
$fastacmd = "$HOME/bin/blast/fastacmd";
$etc      = "$HOME/code/etc/etc";
$clustalw = "/home/protean2/LSETtools/bin/linux/clustalw";
$color_by_coverage = "$HOME/perlscr/pdb_manip/cbcvg.pl";
$remove_matching = "$HOME/perlscr/filters/remove_matching_fasta.pl";
$psi_it   = 3;

open ( ERRLOG, ">errlog") ||
    die "Cno errlog:$! \n.";
 

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

$home = `pwd`;
chomp $home;

$nice_level = "";

while ( <NAMES> ) { 
   
    $begin = time;
    chomp;
    @aux = split;
    $name = $aux[0];
    $name =~ s/\s//g;

    $query     = "$name.seq";
    $blastout  = "$name.blastp";
    $gifile    = "$name.gi";
    $fastafile = "$name.fasta";
    $msffile   = "$name.raw.msf";
    $pdbfile   = "$name.pdb";
    $epifile   = "$name.epitope";

    print "\n $name:\n"; 
    chdir $home ||
	die "cn chdir $home: $!\n";
    #$dir = (substr $name, 0, 4)."/".$name;
    $dir =  $name;
    chdir "$dir" ||
	 die "cn chdir $dir: $!; current dir is: ".`pwd`."\n";

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

    #blast -> returning gi's
    print "\t running blast ... \n"; 
    print "\t               writing to $blastout \n"; 
    $evalue =  1.e-5;
    $commandline = "$blast -p blastp -d $database -i $query -o $blastout -e $evalue  -v  400   -b  400 -K 500   -m 9";
    #$commandline = "nice $nice_level  $blast -j $psi_it -d $database -i $query -o $blastout -e 1.0e-10 -b 1000 -K 500 -m 9";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("blast");
	next;
    }
    print "\t               ... done \n"; 
    #next;

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
    


    # extract seq's by gi
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

    # clip to match the query
    print "\t clipping to the query length ... \n"; 
    open ( FFTMP, "<$fastafile.tmp") ||
        die "cno $fastafile.tmp: $! \n";
    open ( FF, ">$fastafile") ||
        die "cno $fastafile: $! \n";

    if (defined %found) {
	undef %found;
    }
    $gi = $name;
    $paghetti = $original;
    process_spaghetti(1);

    $usable_seqs = 0;
    TOP: while ( <FFTMP>) {
        if ( /\d/ ) {
	    if (/^>/ ) {
		#print;
	        @aux = split ('\|');
	        $gi  = $aux[1];
	            $paghetti = "";
	        while ( <FFTMP>) {
		    if (/^>/ ){
			process_spaghetti(0);
			redo TOP;
		    }
		    chomp;
		    $paghetti .= $_;
		}
	    }
	}
    }
    process_spaghetti (0); 
    close FF;
    close FFTMP;
    `rm $fastafile.tmp`;
    print "\t                  ... done\n"; 
    
    if ( $usable_seqs <=3 ) {
	print "\tonly $usable_seqs usable seqs found. moving on.\n";
    	print ERRLOG "\n$name: only $usable_seqs usable seqs found.\n";
	next;
    }

    # remove substrings from fasta
    print "\t removing substrings from fasta ... \n"; 
    $commandline = "$remove_matching $name";
    $retval   = system ($commandline);
    if ( $retval ) {
	printf "retval: $retval \n";
	process_failure("remove_matching_fasta");
	next;
    }
    print "\t                  ... done\n"; 


    # align
    print "\t running clustalw ... \n"; 
    $commandline = "$clustalw -infile=$fastafile -outfile=$msffile -output=gcg -quicktree > /dev/null";
    $retval   = system ($commandline);
    if ( $retval < 1) { # the dumbos exit with something on succes
	printf "retval: $retval \n";
	process_failure("clustalw");
	next;
    }
    print "\t                  ... done\n"; 


    next;
    # trace

    print "\t running trace ... \n"; 

    $outname = "raw";
    $commandline = "$etc -p $msffile -o $outname  -x $name $name.pdb -c -realval "; 
    #if ( -e $epifile ) {
    #     commandline .= " -epitope $epifile ";
    #}
    #$commandline .= " >&  $logname";
    $retval   = system ($commandline);
    if ( $retval ) {
	printf "retval: $retval \n";
	process_failure("remove_matching_fasta");
	next;
    }
    print "\t                  ... done\n"; 



    $outname = "pr5";
    $logname = "pr5.log";
    $commandline = "$etc -p $msffile -o $outname  -prune 5  -x $name $name.pdb -c -realval "; 
    #if ( -e $epifile ) {
    #	$commandline .= " -epitope $epifile ";
    #}
    #$commandline .= " >&  $logname";
    $retval   = system ($commandline);
    if ( $retval ) {
	printf "retval: $retval \n";
	process_failure("remove_matching_fasta");
	next;
    }
    print "\t                  ... done\n"; 



    #color-by-cluster
    print "\t color-by-coverage ... \n"; 
    $commandline = " $color_by_coverage $outname.ranks_sorted $name.pdb ";
    $retval   = system ($commandline);
    if ( $retval != 0 ) {
	process_failure("cbc");
	next;
    }

    print "\t                  ... done (", time-$begin, "s)\n"; 
}

close ERRLOG;


sub process_spaghetti () {
    
	$is_query = $_[0];
		    @seq = split ('', $paghetti);
		    if ( $paghetti =~ /[BXZbxz]/ ) {
			print "\t                  $gi has X\n"; 
			return;
		    }
		    if ( !$is_query ) {
			@dat = split (' ',$data{$gi});
			$query_start = $dat[6];
			$query_end   = $dat[7];
			$query_len   = $query_end - $query_start + 1;
			$subj_start  = $dat[8];
			$subj_end    = $dat[9];
		
			$subj_max    = $#seq + 1;
			$subj_len    = $subj_end  - $subj_start  + 1;

			
			$min = $subj_start-$query_start+1;
			if ( $min < 1 ) {
			    $min = 1; # max possible comp
			}
			
			
			$max = $subj_end + $query_max - $query_end;
			if ( $max > $subj_max ) { # reverse change
			    $max = $subj_max;
			}
			

		    } else {
			$min = 1;
			$max = $#seq+1;
		    }

	$new_seq =  join ('',@seq[$min-1 .. $max-1]);

	if ( $is_query || !defined $found{ $new_seq } ) {
	    $found{ $new_seq  } = $gi;
	    print FF "> $gi\n";
	    foreach $i ( $min-1 .. $max-1) {
		print FF  $seq[$i];
		if (!(($i-$min+2)%50) && $i !=  $max-1) {
		    print FF "\n";
		}
	    }
	    print FF"\n";
	    $usable_seqs ++;
	} else {
	    print "\t                  $gi found already:";
	    print $found{ $new_seq  }, "\n"; 
	}
		   
}



sub process_failure  {
    	print ERRLOG "\n$name: $_[0] failure.\n";
	print ERRLOG "\texit value: ", $? >> 8, "\n"; 
	print ERRLOG "\t signal no: ", $? & 127, "\n"; 
	if ( $? & 128 ) {
	    print ERRLOG "\tcore dumped.\n";
	}
}
