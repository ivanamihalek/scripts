#! /usr/bin/python
# Loop refinement of an existing model
from modeller import *
from modeller.automodel import *

import sys


#########################################
def main():
    
    if len(sys.argv)<6:
        print "usage: %s <pdb>> <sequence file>  <chain> <from> <to>" % sys.argv[0]
        print "\t pdb should contain a single chainf, with a gap from-to residues"
        print "\t the missing seqeunce should be in the plain text file ('sequence file')"
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
