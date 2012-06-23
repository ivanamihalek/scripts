#! /usr/bin/perl -w

$name = "1guw";
$etc = "/home/protean5/imihalek/trace+/etc/etc"; 
for $i ( 1..25 ) {
    print " $name.model$i.pdb \n";
    #$retval = `pretrace -i $name.model$i.pdb -o pt_$name.model$i > /dev/null`;
    #print "pretrace done:\n $retval\n";
    $exec_string = "$etc  -p $name.i.pruned.msf -o $name.newstat.$i ";
    $exec_string .= "-x pt_$name $name.model$i.pdb pt_$name.model$i.access ";
    $exec_string .= " -sim2 100 ";
    print "$exec_string\n";
    $retval = `$exec_string`;  
    print "$retval\n";
}
