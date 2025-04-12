#! /usr/bin/perl -w

# produce a script for gnuplot
# to make 3x8 multiple plot

use IO::Handle;         #autoflush
# FH -> autoflush(1);
$layout = "portrait"; 
$column_size = 3;
$colx = 4;
$coly = 7;
$ctr_begin = 0;
$outname = "hgz_vs_clustz.ps";
open ( GPSCR, ">tmp.gpscr") ||
    die "Cno tmp.gpscr: $!.\n"; 

print GPSCR  "set nokey\n"; 
print GPSCR  "set term  post $layout enhanced color\n";
#print GPSCR  "set term  jpeg\n";
print GPSCR  "set output \"$outname\" \n";
print GPSCR  "set multiplot\n"; 

print GPSCR  "set yrange [ -1:8.0]\n"; 
print GPSCR  "set xrange [ -1:8.0]\n"; 
print GPSCR  "set  ytics 2.0\n";
print GPSCR  "set  xtics 2.0\n";

print GPSCR  "set ls 1  pt 6 \n";
print GPSCR  "set data style points \n";
print GPSCR  "set pointsize 0.5 \n";
print GPSCR  "set size 1, 1; set origin 0,0; clear \n";
print GPSCR  "set size 0.45, 0.3 \n";
print GPSCR  "set bmargin 0 \n";
print GPSCR  "set tmargin 0 \n";
print GPSCR  "set lmargin 1 \n";
print GPSCR  "set rmargin 0 \n";
print GPSCR  "set ticscale 0.4 0 \n";
print GPSCR  "set format y \n";
#print GPSCR  "f(x) = a*x+b\n";

$x_offset  = 0.1;
$y_offset  = 0.07;
$x_width   = 0.29;
$y_height  = 1/$column_size - 0.03;

$ctr_shifted = 0;
while ( <> ) {
    next if ( !/\S/ );
    chomp;
    @aux = split;
    $name = $aux[0];
    $dir = $name;
    $table1 =  "$dir/" ; 
    next if ( ! -e $table1 );
    print "$name\n";
    if ( $ctr_shifted >= $ctr_begin ) {
	$ctr = $ctr_shifted - $ctr_begin; 
	$name =~ s/\s//g;
	if ( $ctr == $column_size ) {
	    print GPSCR  "set format y \"\"\n";
	    $x_width   = 0.26;
	    $x_offset += 0.03;
	}
		  
	if ( ! ($ctr%$column_size) ) {
	    print GPSCR  "set format x\n";
	    print GPSCR  "set xtics 2\n";
	    $x_o = $x_offset + int ($ctr/$column_size) * $x_width;
	    $x_s = $x_width;
	    $y_o = $y_offset - 0.01;
	    $y_s = $y_height + 0.01;
	} else {
	    $x_o = $x_offset + int ($ctr/$column_size) * $x_width;
	    $y_o = $y_offset + ($ctr%$column_size) * $y_height;
	    $x_s = $x_width;
	    $y_s = $y_height;
	    print GPSCR  "set format x \"\"\n";
	}
	print GPSCR  "set size   $x_s, $y_s \n";
	print GPSCR  "set origin $x_o, $y_o \n";
	print GPSCR  "set nolabel; set label \"$name\"  at 0.0, 7.0\n";
	#print GPSCR  "fit f(x) \'$table\' u $colx:$coly  via a,b \n";
	print GPSCR  "plot ";

	print GPSCR  " \'$table\' u $colx:$coly, f(x) ";
	#print GPSCR  " \'$table\' u $colx:$coly ";
	print GPSCR  "\n";
	print GPSCR  "#\n";
    }
    $ctr_shifted ++;
    last if ( $ctr_shifted-$ctr_begin  == 3*$column_size);
}
print GPSCR  "set nomultiplot\n"; 

close GPSCR;



`/usr/bin/gnuplot tmp.gpscr`;
`rm tmp.gpscr`;
`gv $outname`;
