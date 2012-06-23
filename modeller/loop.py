#! /usr/bin/python
# Loop refinement of an existing model
from modeller import *
from modeller.automodel import *

log.verbose()
env = environ()

# directories for input atom files
env.io.atom_files_directory = ['.', '.']

# Create a new class based on 'loopmodel' so that we can redefine
# select_loop_atoms (necessary)
class MyLoop(loopmodel):
    # This routine picks the residues to be refined by loop modeling
    def select_loop_atoms(self):
        # One loop from residue 19 to 28 inclusive
        return selection(self.residue_range('394:A', '403:A'))

m = MyLoop(env,
           inimodel='test_dummy.pdb', # initial model of the target
           sequence='test_dummy')               # code of the target

m.loop.starting_model= 1           # index of the first loop model
m.loop.ending_model  = 3           # index of the last loop model
m.loop.md_level = refine.very_fast  # loop refinement method

m.make()
