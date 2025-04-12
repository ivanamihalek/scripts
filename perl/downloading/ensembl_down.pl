#! /usr/bin/perl -w

use strict;
use Net::FTP;

my $local_repository = 
    "/home/ivanam/databases/ensembl/fasta";

my $ftp_address = "ftp.ensembl.org";

my $ftp = Net::FTP->new( $ftp_address , Debug => 0, Passive=> 1)
    or die "Cannot connect to $ftp_address: $@";

$ftp->login("anonymous",'-anonymous@')
    or die "Cannot login ", $ftp->message;

my $topdir = "/pub/release-68/fasta";
$ftp->cwd($topdir)
    or die "Cannot cwd to $topdir: ", $ftp->message;
$ftp->binary;

my @farm = $ftp->ls;
my $animal;


my @skip = ("ancestral_alleles", "ciona_intestinalis",  
	 "ciona_savignyi", "drosophila_melanogaster",
	    "saccharomyces_cerevisiae");


my ($dir, $local_dir, $foreign_dir,  @contents, $item, $unzipped);

open (LOG, ">log") || die "error opening log: $!\n";

foreach $animal ( reverse(@farm) ) {

    next if ( grep {/$animal/} @skip);

    print $animal, "\n";


    foreach $dir  ( "pep",  "dna" ){
    
	$local_dir = "$local_repository/$animal/$dir" ;
	( -e $local_dir )  || `mkdir -p $local_dir`;

	$foreign_dir = "$topdir/$animal/$dir";

	$ftp->cwd($foreign_dir)
	    or die "Cannot cwd to $foreign_dir: ", $ftp->message;
	
	my @contents =  $ftp->ls;
	my $item;

	foreach $item (@contents) {

	    next if  ($item !~ /\.gz$/);
	    next if  ($item =~ /\.dna_sm\./);
	    next if  ($item =~ /\.dna_rm\./);
	    print "\t$item\n";

	    $unzipped = $item;
	    $unzipped =~ s/\.gz$//;

	    if ( -e "$local_dir/$unzipped" ) {
		print "\t\t $unzipped found in $local_dir\n";
		next;
	    }

	    $ftp->get($item)
		or die "getting $item  failed ", $ftp->message;

	    `mv  $item  $local_dir`;
	    
	    print "\t\t $item moved to $local_dir\n";

	    if (system ( "gunzip $local_dir/$item" )) {
		print LOG "error uncompressing $local_dir/$item.\n";
		print     "\t\terror uncompressing $local_dir/$item.\n";
	    } else {
		print "\t\t $item unzipped \n";
	    }
	}
    }
}
   
close LOG;
