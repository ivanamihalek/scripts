#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined $ARGV[1]  ||
    die "Usage: rename_and_align.pl  <fastafile>  <msffile> [-tcof]\n"; 

$fastafile=  $ARGV[0] ;
$newmsf    = $ARGV[1];
$tcof = 0;
if ( defined $ARGV[2] ) {
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

$name_string = `grep '>' $fastafile | awk -F '>' '{print \$2}'`;



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


`$gi2name  table1 $fastafile > tmp.fasta`;
`$align -infile= tmp.fasta -outfile= tmp.msf >& /dev/null`;


`$gi2name  table2  tmp.msf > $newmsf`;

`rm table1 table2 tmp.fasta tmp.msf`;
