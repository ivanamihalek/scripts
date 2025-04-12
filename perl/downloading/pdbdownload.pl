#! /usr/bin/perl
# Ivana, Dec 2001
# make pdbfiles directory  and download the pdbfiles
# for proteins with names piped in

use strict;
use warnings FATAL => 'all';


defined ( $ARGV[0] &&  $ARGV[1]) ||
    die "Usage: pdbdownload.pl  <storage dir>  <pdbname>|<file with pdbnames>.\n";

my $storage_dir = shift @ARGV;
if (! -d   $storage_dir) {
    print "$storage_dir not found or does not exist\n";
    exit (1);
}

my @pdbnames = ();
if ( -e $ARGV[0]  ) {
    @pdbnames = split "\n", `cat $ARGV[0]`;
} else {
    push @pdbnames, $ARGV[0];
}

foreach my $pdbname (@pdbnames) {

    $pdbname =~ s/\s//g;
    my @aux  = split ('\.', $pdbname); # get rid of extension
    $pdbname =  lc substr ($aux[0], 0, 4);
    if (-e "$storage_dir/$pdbname.pdb" ) {
        print "$pdbname.pdb found in $storage_dir\n";
        next;
    }
    print $pdbname, " \n";

    my $url = "http://www.pdb.org/pdb/download/downloadFile.do?fileFormat=pdb&structureId=$pdbname";
    system("wget '$url' -O $pdbname.pdb");
    print "\t downloaded $pdbname.pdb\n";

    # system ( "gunzip $pdbname.pdb.gz" ) &&
    #     die "error uncompressing  $pdbname.pdb.gz.\n";
    # print "\t uncompressed $pdbname.pdb.gz\n";

    `mv  $pdbname.pdb $storage_dir/$pdbname.pdb`;

    print "\t moved $pdbname.pdb to $storage_dir \n";
}
