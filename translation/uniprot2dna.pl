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

(defined $ARGV[0] ) ||
    die "Usage: uniprot2dna.pl <name list>.\n";

open ( IF, "<$ARGV[0]" ) ||
    die "Cno $ARGV[0]: $!.\n";

$database   = "/home/pine/databases/uniprot";
$CoDing     = "/home/pine/databases/cds_dbm/cds_rekeyed.dat";

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


    } else { 
	print "entry for $id not found.\n";
    }
}


#untie the databse
undef $db;
untie %database;

close DATAFILE;

close ERRLOG; 

