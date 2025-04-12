#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: ssz_gifs.pl <name_list>\n";

$raster = "/home/protean5/imihalek/projects/seqselect/both/tools/raster.pl";
$matrixplot = "/home/protean5/imihalek/c-utils/graphics/matrixplot";
open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";
while ( <NAMES> ) {
   
    if ( /\w/ ) {
	$begin = time;
    
	chomp;
	@aux = split ' ';
	$name = $aux[0];
	$noc = $aux[2];
	$name =~ s/\s//g;
	$query_name =  $name;
	$name1 = "new";
	$name2 = "old";
	chdir $name ||
	    die "cn chdir $name: $!\n";
	print "\n $name:\n"; 
	if ( -e "$name1.cluster_overlap" && -e "$name2.cluster_overlap" ) {

	    (! -e "$name1.dat" ) || `rm $name1.dat`;
	    (! -e "$name2.dat" ) ||  `rm $name2.dat`;

	    `$raster $name1.cluster_overlap > $name1.dat`;
	    $line = `$matrixplot $name1.dat  `; 
	    @aux = split ' ', $line;
	    $max = $aux[2];

	    `$raster $name2.cluster_overlap > $name2.dat`;
	    $line = `$matrixplot $name2.dat `; 
	    @aux = split ' ', $line;
	    if ( $max < $aux[2] ) {
		$max =  $aux[2];
	    }

	    `$matrixplot $name1.dat $max `;
	    `ppmtogif matrix.ppm > $name1.gif`; 
	    
	    `$matrixplot $name2.dat  $max  `; 
	    `ppmtogif matrix.ppm > $name2.gif`; 
	  
	}
	chdir "../";
    } 
    
}


