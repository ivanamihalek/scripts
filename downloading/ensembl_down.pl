#! /usr/bin/perl -w

use strict;
use Net::FTP;

my $FILE_REPOSITORY = 
    "/afs/bii.a-star.edu.sg/dept/biomodel_design/Group/ivana/databases/ensembl";

my $ftp_address = "ftp.ensembl.org";

my $ftp = Net::FTP->new( $ftp_address , Debug => 0, Passive=> 1)
    or die "Cannot connect to $ftp_address: $@";

$ftp->login("anonymous",'-anonymous@')
    or die "Cannot login ", $ftp->message;

my $topdir = "/pub/current/fasta";
$ftp->cwd($topdir)
    or die "Cannot cwd to $topdir", $ftp->message;
$ftp->binary;

my @farm = $ftp->ls;
my $animal;


open (LOG, ">log") || die "error opening log: $!\n";

foreach $animal ( @farm ) {

    print $animal, "\n";

    my $dir = "$topdir/$animal/pep";
    my $local_dir = "$FILE_REPOSITORY/$animal" ;

    next if ( -e $local_dir);

    $ftp->cwd($dir)
	or die "Cannot cwd to $dir", $ftp->message;
    my @contents =  $ftp->ls;
    my $item;
    foreach $item (@contents) {
	next if  ($item !~ /\.gz$/);
	print "\t$item\n";
	$ftp->get($item)
	    or die "getting $item  failed ", $ftp->message;
	(-e $local_dir) || `mkdir $local_dir`;
	`mv  $item  $local_dir`;
	if (system ( "gunzip $local_dir/$item" )) {
	    print LOG "error uncompressing $local_dir/$item.\n";
	    print     "error uncompressing $local_dir/$item.\n";
	} else {
	    print "\tunzipped $item and saved to $local_dir\n";
	}
    }
}
   
close LOG;
