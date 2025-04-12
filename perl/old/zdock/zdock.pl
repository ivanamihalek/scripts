#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);


$ZDOCK_PATH = "/usr/bin/zdock2.3_linux_p3/";

(defined $ARGV[1]) ||
    die "Usage: zdock.pl <pdb_name_1> <pdb_name_2>.\n";

$name1 = $ARGV[0];
$name2 = $ARGV[1];
 

(-e "uniCHARMM" ) ||  `ln -s $ZDOCK_PATH/uniCHARMM .`;
(-e "$name1.sur.pdb" ) ||
    `$ZDOCK_PATH/mark_sur $name1.pdb $name1.sur.pdb`;
(-e "$name2.sur.pdb" ) ||
    `$ZDOCK_PATH/mark_sur $name2.pdb $name2.sur.pdb`; 

(-e "zdock.out" ) ||
    `$ZDOCK_PATH/zdock -R  $name1.sur.pdb -L $name2.sur.pdb -o zdock.out -N 20`;

`$ZDOCK_PATH/create.pl zdock.out`;

print `ls *.pdb`;
