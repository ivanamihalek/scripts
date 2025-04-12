#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);


$ZDOCK_PATH = "/usr/bin/zdock2.3_linux_p3/";

($name1, $name2) = @ARGV;

   

`ln -s $ZDOCK_PATH/uniCHARMM`;
`$ZDOCK_PATH/mark_sur  $name1.pdb $name1.sur.pdb`;
`$ZDOCK_PATH/mark_sur  $name2.pdb $name2.sur.pdb`; 
print `ls 1*.pdb`;
    

