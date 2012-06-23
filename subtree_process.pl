#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined  $ARGV[2] ) ||
    die "Usage: subtree_process.pl  <nhx_rootname>  <fastafile>  <pdb_rootname>.\n"; 

$name = $ARGV[0];
$fastafile = $ARGV[1];
$pdb = $ARGV[2];


$etc = "/home/i/imihalek/code/etc/wetc";
#$zz =  "/home/i/imihalek/projects/ppint/tools/zz";

`extr_names_from_nhx.pl $name.nhx > $name.gi`;
`extr_seqs_from_fasta.pl  $name.gi  $fastafile > $name.fasta`;
`clustalw -output=gcg  -quicktree -infile= $name.fasta -outfile = $name.msf > /dev/null`;
`$etc -p  $name.msf  -c  -x $pdb  $pdb.pdb -o $name`;
#`$zz dimer.pdb $name.ranks   $name.ranks > $name.zz`;
