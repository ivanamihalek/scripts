#! /usr/bin/perl -w

$inf = "cube.colors_table";
#$inf    = "pde_blncd.color_table";

$colors_pml     = $inf.".clr.pml";
$selections_pml = $inf.".sel.pml";

open (IF, "<$inf") || die "Cno $inf: $!\n";

open (CLR, ">$colors_pml") || die "Cno $colors_pml: $!\n";



($type,  $resi, $num, $nbr_entr, @color) = ();
@residue = ();
$ctr     = 0;

while (<IF>) {
    chomp;
    ($type, $resi, $num, $nbr_entr,  @color) = split;
    $colstr = join ", ", @color;

    $exponent=  ($nbr_entr-0.5)/0.5;
    $transp  = sprintf "%6.2f", 1- exp(-$exponent*$exponent);
    
    print  CLR "set_color blah$ctr, [$colstr]\n";
    print  CLR "color blah$ctr, resi $resi\n";
    print  CLR "set sphere_transparency, $transp, color blah$ctr\n";

    @{$colors[$ctr]} = @color;
    push @residue, $resi;

    $ctr++;
}

$number_of_residues = $ctr;

close CLR;


@corner = (  [0, 0, 0],
	     [0, 0, 1],
	     [0, 1, 0],
	     [1, 0, 0],
	     [0, 1, 1],
	     [1, 0, 1],
	     [1, 1, 0],
	     [1, 1, 1]);

@meaning = ("context_change", 
	    "vatiable",
	    "other_determinant",
	    "my_dterminant",
	    "Loss_of_Fn",
	    "Gain_of_Fn",
	    "discriminant",
	    "conserved");


for $ctr ( 0 .. $number_of_residues-1) {
    
    for $corner_ctr ( 0 .. 7) {

	$distance[$corner_ctr][$ctr] = 0.0;
	for $i (0 ..2) {
	    $aux = $corner[$corner_ctr][$i] - $colors[$ctr][$i];
	    $distance[$corner_ctr][$ctr] += $aux*$aux;
	}
	$distance[$corner_ctr][$ctr] = 
	    sqrt ($distance[$corner_ctr][$ctr]);
    }
}

# sort 

@index =  ( 0 .. $number_of_residues-1);
for $corner_ctr ( 0 .. 7) {

    @{$sorted[$corner_ctr]} = 
	sort { $distance[$corner_ctr][$a] <=> $distance[$corner_ctr][$b] } @index;

}

open (SEL, ">$selections_pml") || die "Cno $selections_pml: $!\n";

for $corner_ctr ( 0 .. 7) {
    #$sorted_ctr = $sorted[$corner_ctr][0];
    #next if ($distance[$corner_ctr][$sorted_ctr] > 0.2);
    print SEL "# corner @{$corner[$corner_ctr]}: $meaning[$corner_ctr]\n";
    print SEL "select $meaning[$corner_ctr], resi ";
    #for $ctr ( 0 .. $number_of_residues-1 ) {
    for $ctr ( 0 .. 20 ) {
	$sorted_ctr = $sorted[$corner_ctr][$ctr];
	#last if ($distance[$corner_ctr][$sorted_ctr] > 0.2);
	$ctr && print SEL  "+";
	$sorted_ctr = $sorted[$corner_ctr][$ctr];
	print SEL $residue[$sorted_ctr];
    }
    print SEL "\n\n";
}

close SEL;



=pod
for $corner_ctr ( 0 .. 7) {
    #$sorted_ctr = $sorted[$corner_ctr][0];
    #next if ($distance[$corner_ctr][$sorted_ctr] > 0.2);

    print  "%% corner @{$corner[$corner_ctr]}: $meaning[$corner_ctr]\n";
    #for $ctr ( 0 .. $number_of_residues-1 ) {
    for $ctr ( 0 .. 20 ) {
	$sorted_ctr = $sorted[$corner_ctr][$ctr];
	#last if ($distance[$corner_ctr][$sorted_ctr] > 0.2);
	printf "%2d %4d %8.3f\n", $ctr,
	$residue[$sorted_ctr], $distance[$corner_ctr][$sorted_ctr];
    }
    print  "\n\n";
}



    @tfmd_color = map { sprintf "%5.3f", (1-cos ($_*3.14))/2.0 }  @color;
    if (0) {
	for $i ( 0 .. 2) {
	    if ($color[$i]>= 0.5 &&  $color[$i] < 0.7) {
		$tfmd_color[$i] = 0.7;
	    } elsif ($color[$i] < 0.5 &&  $color[$i] > 0.3) {
		$tfmd_color[$i] = 0.3;
	    } else {
		$tfmd_color[$i] = $color[$i];
	    }
	}
    } else  {

	for $i ( 0 .. 2) {
	    if ($color[$i]>= 0.5) {
		$tfmd_color[$i] = 1.0 ;
	    } else {
		$tfmd_color[$i] = 0.0;
	    }
	}	
    }

    $colstr = join ", ", @tfmd_color;
=cut
