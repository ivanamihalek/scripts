#! /usr/bin/perl -w
use  DB_File; # Bekeley database stuff
use IO::Handle;         #autoflush
# FH -> autoflush(1);

#  1a) input a seq in fasta format
#  2a) blast agains swissprot
#  3a) obtain EMB accession number

#  4) download CoDing entry
#  5) extract protein and DNA seqs from it - in separate directory each

#  6) check wheter  DNA and protein entries match
$HOME = `echo \$HOME`;
chomp $HOME;

$database   = "/home/pine/databases/uniprot";
$CoDing     = "/home/pine/databases/cds_dbm/cds_rekeyed.dat";
$blast      = "$HOME/bin/blast/blastall";
$compare    = "$HOME/perlscr/dna_prot_compare.pl";
$evalue     =  1.e-5;
$clust      = "/home/protean2/LSETtools/bin/linux/clustalw  -output=gcg  -quicktree";
$extr_names = "/home/i/imihalek/perlscr/extractions/extr_names_from_msf.pl";
$extr_fasta = "/home/i/imihalek/perlscr/extractions/extr_seqs_from_fasta.pl"; 
$phylip2msf = "/home/i/imihalek/perlscr/translation/phylip2msf.pl";
$cleanup    = "/home/i/imihalek/perlscr/msf_manip/cleanup_msf.pl";
$d2p        = "/home/i/imihalek/perlscr/dnaalmt_from_prot.pl";
$descr      = "/home/i/imihalek/perlscr/var_ID_descr.pl";

open ( ERRLOG, ">errlog") ||
    die "Cno errlog:$! \n.";
 
# initialize the db

%database = ();
($db = tie %database, 'DB_File', $CoDing, O_RDWR, 0444)
    || die "cannot open database: $!.\n";
$fd = $db->fd();
open DATAFILE, "+<&=$fd"
    ||  die "Cannot open datafile: $!.\n";


$home = `pwd`;
chomp $home;


while ( <> ) {
    chomp;
    @aux = split;
    $name = $aux[0];
    $proxy = "";
    $idlist = $name.".uniprot_id";

    chdir $home."/$name";

    ######################################################################################
    #blast
    $query = $name.".seq";
    $blastout = $name.".uniprot.blastp"; 
    if ( ! -e  $blastout ) {
	print "\t running blast ... \n"; 
	print "\t               writing to $blastout \n"; 
	$commandline = "nice $blast -p blastp -d $database -i $query -o $blastout -e $evalue  -v  400   -b  400 -K 500 ";
	$retval   = system ($commandline);
	if ( $retval != 0 ) {
	    process_failure("blast");
	    next;
	}
	print "\t               ... done \n"; 
    } else {
	print "\t $blastout found ... \n"; 
    }
    ######################################################################################
    # find uniprot names
    print "\t extracting uniprot ids ... \n"; 
    open ( IF, "<$blastout" ) || die "Cno $blastout: $!.\n";
    open (OF, ">$idlist" ) || die  "Cno $idlist: $!.\n";
    $reading = 0;
    while ( <IF> ) {
	if ( /Sequences producing significant alignments/ ) {
	    $reading = 1;
	    last;
	}
    }
    if ( ! $reading ) {
	seek IF, 0, 0;
    }
    while ( <IF> ) {
	last if ( /^>/ );
	next if ( !/\S/ ) ;
	@aux = split;
	$aux[1] =~ s/\(//g;
	$aux[1] =~ s/\)//g;
	print OF "$aux[1]\n";
	#the first name is the most similar to my original query
	if ( !  $proxy) {
	    $proxy = $aux[1];
	}
    } 
    close IF;  
    close  OF;
    print "\t               ... done \n"; 

    ###################################################################################### 
    # extract nt and aa sequences
    %failure = ();
    print "\t looking for  nt and aa sequences ... \n"; 
    open (IF, "<$idlist" ) || die  "Cno $idlist: $!.\n";
    while ( <IF> ) {
	chomp;
	$id = $_;
	print "$id\n";
	#look it up
	$ret = $database{$id};
	if ( defined $ret ) {
	    #print $ret; exit;
	    # extract nucleotide and translation parts
	    @lines = split '\n', $ret;
	    $reading = 0;
	    $filename = "$id.aa.fasta";
	    open ( OF, ">$filename" ) ||
		die "Cno $filename.\n"; 
	    print OF "> $id\n";
	    $ctr = 0;
	    TOP: foreach $line ( @lines) { 
		if ( $reading ) {
		    last if ( $line =~ /^SQ/ ||  $line =~ /^XX/ ); 
		    $line =~ s/\"//g; 
		    $line =~ s/\=//g; 
		    $line =~ s/\/translation//g;
		    $line = substr ($line, 21);
		    print OF  "$line\n"; 
		    $ctr += ($line =~ s/\w//g);
		}elsif ( $line =~ /\/translation/ ) { 
		    $reading = 1; 
		    redo TOP; 
		} 
	    } 
	    close OF; 
	    $filename = "$id.nt.fasta";
	    open ( OF, ">$filename" ) ||
		die "Cno $filename.\n"; 
	    print OF "> $id\n";
	    $ctr = 0;
	    $nonstandard = 0; # nonstandard nucleotide
	    foreach $line ( @lines) {
		next if ( $line !~ /\S/ );
		next if ( substr ($line, 0, 2) =~ /\S/ );
		$line = substr ($line,0, 70);
		if ( $line =~ /[^ACTGactg\s]/i ) {
		    $nonstandard = 1;
		}
		print OF  "$line\n";
		$ctr += ($line =~ s/\w//g);
	    }
	    close OF;

	    if (  $nonstandard  ) {
		print "\t nonstandard \n";
		$failure{$id} = "nonstandard";
		next;
	    }
	    $table = 1;
	    if ($ret =~ /\/transl\_table\=(\d+)/ ) {
		$table = $1;
	    }
	    $complement = 0;
	    if ( $ret =~ /complement/ ) {
		$complement = 1;
	    }
	    #print $table,"\n"; exit;
	    #check for mismatches between nt and aa
	    $ret = `$compare $id.nt.fasta $id.aa.fasta $table $complement`;
	    #print $ret;
	    if ( $ret =~ /major mismatch/ ) { 
		$failure{$id} = "major mismatch";
		print  $database{$id};
		exit;
	    }
	} else { 
	    $failure{$id} = "entry for $id not found";
	    print "entry for $id not found.\n";
	}
    }
    print "\t               ... done \n"; 
    if ( defined $failure{$proxy} ) {
	printf "Proxy failure for $name: $failure{$proxy}.  Moving to the next protein.\n";
	next;
    }

    ######################################################################################
    #concatenate all the valid nt and fasta files 
    print "\t concatenating fasta files ... \n"; 
    foreach $type ( "nt", "aa" ) {
	$all{$type} = ""; 
    }
    seek IF, 0, 0;  
    ID: while ( <IF> ) {  
	chomp;
	$id = $_; 
	next if ( defined ( $failure{$id} ));
	foreach $type ( "nt", "aa" ) {
	    $filename = "$id.$type.fasta";
	    
	    open ( FH, "<$filename" ) || next ID;
	    #slurp in the input as a single string
	    undef $/;
	    $_ = <FH>;
	    $/ = "\n";
	    close FH;
	    $all{$type} .= $_;
	}
    } 
    foreach $type ( "nt", "aa" ) {
	$filename  = "$name";
	$filename .= "_all.$type.fasta";
	open ( FH, ">$filename" ) || die "Cno $filename: $!.\n";
	print FH $all{$type};
	close FH;
    }
    print "\t               ... done \n";  


    ######################################################################################
    #align the aa.fasta using clustalw
    print "\t aligning ... \n"; 
    $filename  = "$name";
    $filename .= "_all.aa.fasta";
    $almt_file = "$name";
    $almt_file .= "_all.aa.msf";
    `$clust -infile= $filename -outfile= $almt_file > /dev/null `;
    print "\t               ... done \n"; 
   
    ######################################################################################
    # cleanup this almt to something intersting
    print "\t cleaning up  the alignment ... \n"; 
    `$cleanup $almt_file $proxy  0.75 0.999 0.2 >   tmp.msf`;
    `$extr_names < tmp.msf > tmp.names`;
    `$extr_fasta tmp.names $filename > tmp.fasta`;
    print "\t               ... done \n"; 

    ######################################################################################
    # realign
    print "\t realignment ... \n"; 
    `$clust -infile= tmp.fasta -outfile= $name.clean.aa.msf > /dev/null `;
    print "\t               ... done \n"; 
    

    ######################################################################################
    #protein almt to dna almt
    print "\t translating protein almt to dns ... \n"; 
    $filename  = "$name";
    $filename .= "_all.nt.fasta";
    $ret = `$d2p  $name.clean.aa.msf $filename` || "";
    ( $ret ) && die $ret;
    print "\t               ... done \n"; 


    ######################################################################################
    #convert format from phylip to msf
    print "\t converting from phylip to msf ... \n"; 
    $ret = `$phylip2msf < $name.clean.aa.msf.phylip > $name.clean.nt.msf`;
    ( $ret ) && die $ret;
    print "\t               ... done \n"; 



    ######################################################################################
    #some housekeeping
    (-e "aa_fasta") || `mkdir aa_fasta`;
    `mv *.aa.fasta aa_fasta`;
    (-e "nt_fasta") || `mkdir nt_fasta`;
    `mv *.nt.fasta nt_fasta`;
    `rm *.bkp`;
    `rm tmp.fasta`;
    `rm tmp.names`;

    ######################################################################################
    # make descriptors file
    `$descr < $idlist >  $name.descr`;


    ######################################################################################
    #align the original sequence to the cleaned alignment
    #`$clust -profile1= $name.clean.aa.msf -profile2= $name.seq -outfile= $name.struct_to_clean.msf > /dev/null`;
    
    ######################################################################################
    # quick and dirty way to find mapping btw the almt and the pdbids:
    # run trace and extract the first two columns from the ranks file
    #`$etc -p $name.struct_to_clean.msf -x $name $name.pdb`;
    #`awk \'\$1 != \"\%\" && \$2 != \"-\" && \$1 != \"\" {printf \"%6d  %6d \\n\", \$2,  \$1}' etc_out.ranks > pdbid_to_clenaaapos`;
    #`rm -f etc_out*`;
    # use map_etc_to_struct.pl
   
    
    ######################################################################################
    # run trace on aa almt and map the results on structure

    ######################################################################################
    # run trace on nt almt and map the results on structure


 }
 

#untie the databse
undef $db;
untie %database;

close DATAFILE;

close ERRLOG; 

sub process_failure  { 
    	print ERRLOG "\n$name: $_[0] failure.\n";
	print ERRLOG "\texit value: ", $? >> 8, "\n"; 
	print ERRLOG "\t signal no: ", $? & 127, "\n"; 
	if ( $? & 128 ) {
	    print ERRLOG "\tcore dumped.\n";
	}
}
