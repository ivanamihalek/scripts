#! /usr/bin/perl -w

(@ARGV == 2) ||
    die "Usage:  $0  <in name> <out name> \n";

##########################
$cc_bond_length = 1.54;
$max = 5;
##########################


($filename, $outname) = @ARGV;
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

$carb = "/home/ivanam/perlscr/pdb_manip/carbon_line.pl";


$ctr = 0;
while ( <IF> ) {
    next if ( !/\S/ );
    @aux = split;
    
    $type[$ctr] = $aux[1];
    @{$p[$ctr]} = @aux[2..4];
    $resolution[$ctr] = sprintf "%1.1f", $aux[5];
    print " $ctr $resolution[$ctr]\n";
    $ctr++;
}
close IF;
$no_of_lines = $ctr;



# strand shades of green



#########################################################
#########################################################
#########################################################


foreach $ctr( 0 .. $no_of_lines-1  ) {
    next if ( $resolution[$ctr]>0.5);
    for $i ( 0 .. 2 ) {
	$cm[$i] = $p[$ctr][$i]*$cc_bond_length*$max;
    }
    if ( $type[$ctr] == 1 ) {
	$filename = "HELIX_$ctr.carb.pdb";
    } else {
	$filename = "STRAND_$ctr.carb.pdb";
    }
    open (TMP, ">tmp") || die "Cno tmp: $!.\n";
    printf TMP " %5.2f  %5.2f   %5.2f    %8.2f  %8.2f  %8.2f  \n",
    @{$p[$ctr]}, @cm;
    close TMP;
    $cmd = "$carb tmp $max > $filename";
    (system $cmd ) && die "Error running $cmd: $!.\n";
}



$pymol_scr = "bg_color white\n";
#$pymol_scr .= "set sphere_scale=.4\n\n";
$pymol_scr .= "set line_width, 5.0\n\n";

foreach $ctr (0 .. $no_of_lines-1) {
    next if ( $resolution[$ctr]>0.5);

    if ( $type[$ctr] == 1 ) {
	$filename = "HELIX_$ctr.carb.pdb";
	$objname  = "HELIX_$ctr";
	$red = sprintf "%d", (55 + 200*$resolution[$ctr]*2);
	$green = 0;
	$blue  = 0;
    } else {
	$filename = "STRAND_$ctr.carb.pdb";
	$objname  = "STRAND_$ctr";
	$green = sprintf "%d", (55 + 200*$resolution[$ctr]*2);
	$red   = 0;
	$blue  = 0;
    }
    $pymol_scr .= "load $filename, $objname\n";

    #$pymol_scr .= "show spheres, $objname\n";

    $pymol_scr .= "set_color color_name_$ctr = [$red, $green, $blue]\n";
    $pymol_scr .= "color color_name_$ctr, $objname\n";
    $pymol_scr .= "\n";
}
$pymol_scr .= "zoom all\n";

open (PYM, ">$outname.pml") || die "Cno $outname.pml: $!.\n";
print PYM $pymol_scr;
close PYM;
