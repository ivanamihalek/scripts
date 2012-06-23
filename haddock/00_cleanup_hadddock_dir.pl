#!/usr/bin/perl -w

$home = `pwd`;
chomp $home;

foreach ("cluster_pdbfiles", "jobfiles", "inpfiles", "outfiles") {

    (-e $_) || `mkdir $_`;

}
`mv cluster*.pdb cluster_pdbfiles`;
`mv *.job  jobfiles`;
`mv *.inp  inpfiles`;
`mv *.out  outfiles`;

chdir "structures";

`mv it1/water .`;

chdir "water";

foreach ("pdbfiles", "scorefiles", "assorted_junk") {

    (-e $_) || `mkdir $_`;

}


`mv *.pdb pdbfiles`;
`mv file.nam* scorefiles`;
`mv *.* assorted_junk`;
