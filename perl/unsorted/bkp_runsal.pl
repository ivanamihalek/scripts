#! /usr/gnu/bin/perl

###
###	runsal
###	running SAL program
###
###	Daisuke Kihara, 9.5.2003
###	dkihara@purdue.edu, kihara@buffalo.edu
###
###	Input:	2 pdb files 
###		(edit the files if several chains are included in a file)
###	Output:	stralign.rslt, a result file
###		prot0rot.pdb, prot1rot.pdb, rotated (superimposed) structures
###

if($#ARGV < 1){
	die("usage: runsal PDBfile1 PDBfile2\n");
}

for $i (0..1){

	open(OUT, ">prot$i.real");
	($d, $num, $d2) = split(/\s+/, `grep ^ATOM $ARGV[$i] |grep CA|wc -l`); 
	printf OUT "%13d\n", $num;
	$n = 1;
	open(F, "$ARGV[$i]")||die;
	while(<F>){
		if(/^ATOM/ && /CA/){
			$head[$i][$n] = substr($_, 0, 30);
			$x = substr($_, 29, 8); 
			$y = substr($_, 38, 8); 
			$z = substr($_, 46, 8); 
			printf OUT "%13d%11.5f%15.6f %15.6f\n", $n, $x, $y, $z;
			$n++;
		}
	}
	close F;
	close OUT;
}

system("stralign");

# output rotated structures
for $i(0 .. 1){

	$realfile = 'prot'. $i . 'rot.real';
	$outputfile = 'prot'. $i . 'rot.pdb';

	open(R, $realfile)||die;
	open(OUT, ">$outputfile")||die;
	while(<R>){
		chomp;
		@col = split(/\s+/, $_);

		print OUT $head[$i][$col[1]];
		printf OUT "%8.3f%8.3f%8.3f  1.00  5.00           C\n", $col[2], $col[3], $col[4];
	}
	print OUT "TER\n";
	close R;
	close OUT;
}

exit(0);
