#! /bin/csh
#
# (C) 1999, TSRI.
# Garrett M. Morris
# 
# Usage: mkgpf3 ligand.pdbq macromol.pdbqs
# Needs: gpf3gen (AWK program)
# Needs: pdbcen (AWK program)
#
# -- Reads in the small molecule PDBQ file,
# -- Detects all atom types present in 'ligand.pdbq';
# -- Calculates the center of the macromolecule in 'macromol.pdbqs';
# -- Creates the grid parameter file for AutoGrid 3;
# -- Uses equilibrium separations and well depths to define pairwise 
#    energy potentials;
# -- Defines solvation parameters, based on Stouten, PFW, Fro''mmel, C, 
#    Nakamura, H, and Sander, C: "An effective solvation term based on 
#    atomic occupancies for use in protein simulations", Molecular Simulation 
#    (1993), V.10, pp.97-120.
# -- SolPar is scaled by the 0.1711 factor found in the AutoDock3 free
#    energy force field survey.
#
echo '\
________________________________________________________________________________\
\
mkgpf3\
Version 3.0.4\
(C) 1999, Garrett Morris, TSRI.\
\
Ligand = "'$1'", Macromolecule = "'$2'".\
\
Making "'$2:r'.gpf",  based on the atom types found in "'$1'"\
'
gawk -f $3/gpf3gen.awk $1 >! $1:r.tmp
sed 's/<macromol>/'$2:r'/g' $1:r.tmp  >!  gpf.tmp
#rm -f $1:r.tmp
#$3/pdbcen $1 >! $1:r.gridcenter
# csplit -k -s $2:r.gpf /gridcenter/ /types/
# cat xx00 $1:r.gridcenter xx02 >! $2:r.gpf
# rm -f xx0[0-2] $1:r.gridcenter

echo 'Completed making grid parameter file:  "gpf.tmp"\
________________________________________________________________________________\
'
#
# Usage: mkdpf3 ligand.pdbq macromol.pdbqs
# Needs: dpf3gen (AWK program)
#
echo '\
________________________________________________________________________________\
mkdpf3\
(C) 1999, Garrett Morris, TSRI.\
\
Ligand = "'$1'", Macromolecule = "'$2'".\
\
Making "'$1:r'.'$2:r'.dpf",  based on the atom types found in "'$1'"\
\
...Using "dpf3gen".\
'


gawk -f $3/dpf3gen.awk  $1 >! $1:r'.'$2:r.dpf

sed 's/<macromol>/'$2:r'/g' $1:r'.'$2:r.dpf >! tmp1
sed 's/<smlmol>/'$1:r'/g' tmp1 >! tmp2
mv -f  tmp2 $1:r'.'$2:r.dpf
rm -f tmp1

if (-z $1:r'.'$2:r'.dpf') then
    /bin/rm -f $1:r'.'$2:r'.dpf'
    echo '\
Sorry, I could not create '$1:r'.'$2:r'.dpf\
________________________________________________________________________________\
'
else 
    echo '\
Completed preparing '$1:r'.'$2:r'.dpf\
________________________________________________________________________________\
'
endif
