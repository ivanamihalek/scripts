#!/usr/bin/perl -w

(defined $ARGV[2]) ||
   die "Usage:  cbcvg.pl <specs score file>  <pdb_file_full_path>  <output name> [<chain> and/or -r and/or -b] \n"; 
 

##################################################
#set the pallette:
$COLOR_RANGE = 20;
$green = $blue = $red = 0;

=pod
for ( $ctr=0; $ctr <=$COLOR_RANGE; $ctr++ ) {
    $red = 254;
    $ratio =  $ctr/$COLOR_RANGE;
    $green = $blue =int (sin ($ratio*$PI/2)*254);
    $green = $blue =int (exp($ratio)/exp(1)*254);
}
=cut 

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

=pod
for ( $ctr=0; $ctr <= $COLOR_RANGE; $ctr++ ) {
    print " $ctr  $color[$ctr] \n";

}
#exit;
=cut
##################################################
# input
$ranks_file = $ARGV[0]; 
$pdb_file   = $ARGV[1]; 
$output_file   = $ARGV[2]; 
$chain = "";
$reverse = 0;
$backbone = 0;

for  $argctr ( 3 .. 5 ) {
    if ( defined  $ARGV[ $argctr ] ){
	if ( $ARGV[$argctr ] eq "-r" ) {
	    $reverse  = 1;
	} elsif ( $ARGV[ $argctr ] eq "-b" ) {
	    $backbone  = 1;
	} else {
	    $chain =  $ARGV[3];
	}
    }
}



open (RANKS_FILE, "<$ranks_file") || 
    die "cno $ranks_file\n";
    
($almt,  $pdb_id,    $type,     $gaps,           $substitutions,     $entr,     $entr_cvg,        
 $iv,     $iv_cvg,        $rv,     $rv_cvg,    $entr_s,     $cvg,      $iv_s,     $cvg,      
 $rv_s,     $cvg,     $pheno,     $pheno_cvg,    $ph_hyb,     $cvg,    $ph_nod,    $cvg) = ();

while ( <RANKS_FILE> ) {
    next if ( !/\S/ );
    next if ( /\%/ );
    chomp;

   ($almt,  $pdb_id,    $type,     $gaps,           $substitutions,     $entr,     $entr_cvg,        
    $iv,     $iv_cvg,        $rv,     $rv_cvg,    $entr_s,     $cvg,      $iv_s,     $cvg,      
    $rv_s,     $cvg,     $pheno,     $pheno_cvg,    $ph_hyb,     $cvg,    $ph_nod,    $cvg) = split;

    next if ($pdb_id =~ '-' );

    $cvg{$pdb_id} = $pheno_cvg;
    if ( $reverse ) {
	$cvg{$pdb_id} = 1 - $cvg{$pdb_id};
    }
}



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





