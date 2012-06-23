#!/bin/csh

set rep_path = /home/i/imihalek/projects/report_maker/modular

echo "**************************"
echo "**************************"
echo Q99684    no structure closer than 60%
echo "**************************"
echo "**************************"
set i = Q99684
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..


echo "**************************"
echo "**************************"
echo P38859    no structure at all
echo "**************************"
echo "**************************"
set i = P38859
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo P31946    one  full length structure
echo "**************************"
echo "**************************"
set i = P31946
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo P32754    one full length model structure
echo "**************************"
echo "**************************"
set i = P32754
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo P54253    single segment, 100% identity
echo "**************************"
echo "**************************"
set i = P54253
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo 1elj      single chain with a ligand and a modified residue
echo "**************************"
echo "**************************"
set i = 1elj
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo 1jey      two nonidentical chains with DNA
echo "**************************"
echo "**************************"
set i = 1jey
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo 1ad3   2 identical chains, both explicitly given in the PDB
echo "**************************"
echo "**************************"
set i = 1ad3
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo P13010    two disjunct pieces of structure \(ku80\)
echo "**************************"
echo "**************************"
set i = P13010
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo P02699 bovine rhodopsin - several TM pieces
echo "**************************"
echo "**************************"
set i = P02699
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo 1a59 homodimer which needs to be reconstructed from BIOMT; no chain label
echo "**************************"
echo "**************************"
set i = 1a59
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo Q07889   has a domain \(with structure\), and HSSP has a chain different from the  one chosen by blast
echo "**************************"
echo "**************************"
set i = Q07889
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo 2a8h    no HSSP
echo "**************************"
echo "**************************"
set i = 2a8h
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo 1afv    6 chains, 2x3 - find the right ones in the HSSP
echo "**************************"
echo "**************************"
set i = 1afv
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..

echo "**************************"
echo "**************************"
echo 2btf    error in the HSP entry (no chains)
echo "**************************"
echo "**************************"
set i = 2btf
cd $i
$rep_path/report_maker_3.pl $i
cat
cd ..
