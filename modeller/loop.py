#!/usr/bin/env python
# env gives me minionda python, modeller installed there - otherwise make your own solution
# Loop refinement of an existing model

from modeller import *
from modeller.automodel import *

import sys


#########################################
def main():
    
    if len(sys.argv)<6:
        print "usage: %s <pdb> <loopfile>  <chain> <from> <to>" % sys.argv[0]
        print "\t pdb and loopfile sould be the output of build_dummy.pl"
        print "\t from and to should be the first two numbers in loopfile,"
        print "\t unless we are prepending/appending a sequence"
        print "\t in which case the numbers should be correcte for 3 res on the nonexiting side"
        exit(1)

    [pdbfile, seqfile, chain, chain_from, chain_to] = sys.argv[1:6]
    # directories for input atom files
    env = environ()
    env.io.atom_files_directory = ['.', '.']

    from_label = "{0}:{1}".format (chain_from, chain)
    to_label   = "{0}:{1}".format (chain_to, chain)
    ########################################
    # Create a new class based on 'loopmodel' so that we can redefine
    # select_loop_atoms (necessary)
    class MyLoop(loopmodel):
        # This routine picks the residues to be refined by loop modeling
        def select_loop_atoms(self):
            # One loop from residue 19 to 28 inclusive
            return selection(self.residue_range(from_label, to_label))

    m = MyLoop (env, inimodel=pdbfile, sequence=seqfile )

    m.loop.starting_model= 1           # index of the first loop model
    m.loop.ending_model  = 3           # index of the last loop model
    m.loop.md_level = refine.very_fast  # loop refinement method

    m.make()


#########################################
if __name__ == '__main__':
    main()
