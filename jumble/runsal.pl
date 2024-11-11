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

$CUTOFF = 3.0;

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

=pod
system("stralign");
=cut

@chain0 = ();
@chain1 = ();

# output rotated structures
for $i(0 .. 1){

	$realfile = 'prot'. $i . 'rot.real';
	$outputfile = 'prot'. $i . 'rot.pdb';

	open(R, $realfile)||die;
	open(OUT, ">$outputfile")||die;
	while(<R>){
		chomp;
		@col = split;
		if ( $i) {
		    push @chain1, $col[0];
		    $coord1{$col[0]} = join " ", @col[1..3];
		} else {
		    push @chain0, $col[0];
		    $coord0{$col[0]} = join " ", @col[1..3];
		}
		print OUT $head[$i][$col[0]];
		printf OUT "%8.3f%8.3f%8.3f  1.00  5.00           C\n", @col[1..3];
	}
	print OUT "TER\n";
	close R;
	close OUT;
}



$res1 = pop @chain1;

foreach $res1( @chain1 ) {
    @x1 = split " ",  $coord1{$res1};

    $min_dist = 100.0;
    $min_res =  0;
    foreach $res0 ( @chain0 ) {
	@x0 = split " ",  $coord0{$res0};
	$dist = 0;
	for $i ( 0 ..2 ) {
	    $aux = $x1[$i] -$x0[$i];
	    $dist += $aux*$aux;
	}
	if ( $min_dist > $dist) {
	    $min_dist= $dist;
	    $min_res = $res0;
	}
    } 

    if ( $min_dist <  $CUTOFF ) {
	if ( defined $aligned0{$min_res} ) {
	    $aligned0{$min_res} ++;
	} else {
	    $aligned0{$min_res} = 1;
	}
	if ( defined $aligned1{$res1} ) {
	    $aligned1{$res1} ++;
	} else {
	    $aligned1{$res1} = 1;
	}
	$aligned_with{$res1} = $min_res;
    }
 
}


$unaligned = $multiply_aligned = $uniquely_aligned = 0;
foreach $res1( @chain1 ) {
    if ( ! defined $aligned1{$res1} ) {
	$unaligned ++;
    } elsif ($aligned1{$res1} > 1) {
	$multiply_aligned ++;
    } else {
	$uniquely_aligned++;
    }
}

printf "chain 1:   correctly aligned %4d   multiply %4d   unaligned %4d \n",
    $uniquely_aligned, $multiply_aligned,$unaligned ;

$unaligned = $multiply_aligned = $uniquely_aligned = 0;
foreach $res0( @chain0 ) {
    if ( ! defined $aligned0{$res0} ) {
	$unaligned ++;
    } elsif ($aligned0{$res0} > 1) {
	$multiply_aligned ++;
    } else {
	$uniquely_aligned++;
    }
}

printf "chain 0:   correctly aligned %4d   multiply %4d   unaligned %4d \n",
    $uniquely_aligned, $multiply_aligned,$unaligned ;

=pod
foreach $res1( @chain1 ) {
    if ( !defined $aligned_with{$res1} ) {
	print " -   %4d\n", $res1;
    }

    foreach $res0( @chain0 ) {
	if ( $res0 = $aligned_with{$res1} )
	$partner 
    }
}
=cut
