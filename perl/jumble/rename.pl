#!/usr/gnu/bin/perl -w 
# Ivana,Dec 2001
# rename the files having the old
# pdb file name [ pdb<pdb_name>.ent ]
# to the new standard name [ <PDB_NAME>.pdb ]
while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	if ( $fileName =~ /pdb(\w*)\.ent/) {
	    $newName = uc ($1).".pdb";
	    rename ($fileName, $newName);
	}
    }
}
