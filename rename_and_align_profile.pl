#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined $ARGV[1]  ||
    die "Usage: rename_and_align_profile.pl  <msffile> <seqfile>  <msffile> [-tcof]\n"; 

$file1=  $ARGV[0] ;
$file2=  $ARGV[1] ;
$newmsf    = $ARGV[2];
$tcof = 0;
if ( defined $ARGV[3] ) {
    $tcof = 1;
}

$gi2name = "/home/i/imihalek/perlscr/translation/gi2name.pl";
$clust   = "/home/protean2/LSETtools/bin/linux/clustalw -output=gcg -quicktree";
$tcoffee   = "/home/i/imihalek/T-COFFEE/bin/t_coffee -output=gcg";
if ( $tcof) {
    $align = $tcoffee;
} else {
    $align = $clust;
}

$name_string = `grep Name $file1 | awk '{print \$2}'`;

@name_list = split '\n', $name_string;


$filename = "table1";
open  ( TAB1, ">$filename") || die "Cno $filename: $!.\n";  

$filename = "table2";
open  ( TAB2, ">$filename") || die "Cno $filename: $!.\n";  

$ctr = 0;
foreach $name ( @name_list ) {
    $ctr++;
    $name =~ s/\s//g;
    $newname = "tmp$ctr";
    print TAB1 "$name      $newname\n";
    print TAB2 "$newname     $name \n";
}

close TAB1;
close TAB2;

`$gi2name  table1 $file1 > tmp.msf`;

`$align -profile1= tmp.msf -profile2= $file2  -outfile= tmp2.msf  >& /dev/null`;



`$gi2name  table2  tmp2.msf > $newmsf`;

`rm table1 table2  tmp2.msf tmp.msf`;
