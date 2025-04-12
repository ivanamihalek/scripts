#!/usr/bin/perl -w

 

(defined $ARGV[3]) ||
    die "Usage:  cbcvg.pl  <method [rvet|majf|entr]>  <specs score file>  ".
    " <pdb_file_full_path>  <output name> [<chain> and/or -r and/or -b] \n"; 
($method, $ranks_file, $pdb_file, $output_file) = @ARGV;

##################################################
#set the pallette:
$COLOR_RANGE = 20;
$green = $blue = $red = 0;


$N = 5;
$C1 = $COLOR_RANGE-1;
$red = 254;
$green = int 0.83*254;
$blue =  int 0.17*254;
$color[0] = "[$red, $green, $blue]"; 

for ( $ctr=1; $ctr <= int ($COLOR_RANGE/$N); $ctr++ ) {

    $ratio = ($C1/$N-($ctr-1))/($C1/$N);
    $red   = int ( $ratio * 254);
    $green = $blue = 0;
		 
    $color[$ctr] = "[$red, $green, $blue]"; 

}

for ( $ctr= int ($COLOR_RANGE/$N)+1 ; $ctr <= $COLOR_RANGE; $ctr++ ) {

    $ratio =  ( $ctr -  $COLOR_RANGE/$N)/ ($COLOR_RANGE*($N-1)/$N);
    $red = int ( $ratio * 254);
    $green = $blue = $red;
		 
    $color[$ctr] = "[$red, $green, $blue]"; 

}



##################################################
# input
$chain = "";
$reverse = 0;
$backbone = 0;

for  $argctr ( 4 .. 5 ) {
    if ( defined  $ARGV[ $argctr ] ){
	if ( $ARGV[$argctr ] eq "-r" ) {
	    $reverse  = 1;
	} elsif ( $ARGV[ $argctr ] eq "-b" ) {
	    $backbone  = 1;
	} else {
	    $chain =  $ARGV[4];
	}
    }
}



open (RANKS_FILE, "<$ranks_file") || 
    die "cno $ranks_file\n";
    

$method_column = -1;

while ( <RANKS_FILE> ) {
    next if ( !/\S/ );
    if ( /\%/ ){
	@aux = split;
	shift @aux;
	for ($ctr=0; $ctr< $#aux; $ctr++) {
	    if ($aux[$ctr] eq $method ) {
		$method_column = $ctr;
		last;
	    }
	}
    } elsif ($method_column > -1) {
	chomp;
	@aux = split;
	$pdb_id = $aux[1];
	next if ($pdb_id =~ '-' );
	$cvg{$pdb_id} = $aux[$method_column];
	if ( $reverse ) {
	    $cvg{$pdb_id} = 1 - $cvg{$pdb_id};
	}
    }
}


close RANKS_FILE;


##################################################
# output
format FPTR = 
load @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     $pdb_file
restrict protein
wireframe off
backbone 150
color [255,255,255]
background [255,255,255]
#spacefill
.

# open the output file
if  ($reverse ) {
    $filename = $output_file.".rev";
} else {
    $filename = $output_file;
}

open (FPTR, ">$filename") || die "cno $filename\n";
write FPTR ;

foreach $pos ( keys %cvg ) {
     $color_index = int ($cvg{$pos}*$COLOR_RANGE );
    print FPTR "\n";
    print FPTR "select  $pos";
    if ( $chain ){
	print  FPTR  ":$chain";
    }
    print  FPTR "\n";
    if ( (!$backbone )  ) {
	print FPTR "spacefill\n";
    }
    print FPTR "color $color[$color_index] \n";
    
}



close FPTR; 





