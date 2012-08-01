#!/usr/bin/perl -w

 

(defined $ARGV[3]) ||
    die "Usage:  cbcvg.pl  <method [rvet|ivet|entr|pheno]>  <specs score file>  <pdb_file_full_path>  <output name> [<chain> and/or -r and/or -b] \n"; 
($method, $ranks_file, $pdb_file, $output_file) = @ARGV;

##################################################
#set the pallette:
$COLOR_RANGE = 20;
$green = $blue = $red = 0;


$N = 5;
$C1 = $COLOR_RANGE-1;

$red = 1.00;
$green =  0.83;
$blue =    0.17;
$color[0] = "[$red, $green, $blue]"; 
$color_name[0] = "c0";

$bin_size = $C1/$N;
for ( $ctr=1; $ctr <= int ($COLOR_RANGE/$N); $ctr++ ) {

    $ratio =  ( int ( 100*($bin_size- $ctr+1)/$bin_size) ) /100;
    $red   = $ratio;
    $green = $blue = 0;
		 
    $color[$ctr] = "[$red, $green, $blue]"; 
    $color_name[$ctr] = "c$ctr";

}

for ( $ctr= int ($COLOR_RANGE/$N)+1 ; $ctr <= $COLOR_RANGE; $ctr++ ) {

    $ratio =  ( $ctr -  $COLOR_RANGE/$N)/ ($COLOR_RANGE*($N-1)/$N);
    $red = $ratio;
    $green = $blue = $red;
		 
    $color[$ctr] = "[$red, $green, $blue]"; 
    $color_name[$ctr] = "c$ctr";
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
    
($almt,  $pdb_id,    $type,     $gaps,           $substitutions,     $entr,     $entr_cvg,        
 $iv,     $iv_cvg,        $rv,     $rv_cvg,    $entr_s,     $cvg,      $iv_s,     $cvg,      
 $rv_s,     $cvg,     $pheno,     $pheno_cvg,    $ph_hyb,     $cvg,    $ph_nod,    $cvg, $r4s, $r4s_cvg) = ();


while ( <RANKS_FILE> ) {
    next if ( !/\S/ );
    next if ( /\%/ );
    chomp;

   ($almt,  $pdb_id,    $type,     $gaps,           $substitutions,     $entr,     $entr_cvg,        
    $iv,     $iv_cvg,        $rv,     $rv_cvg,    $entr_s,     $cvg,      $iv_s,     $cvg,      
    $rv_s,     $cvg,     $pheno,     $pheno_cvg,    $ph_hyb,     $cvg,    $ph_nod,    $cvg, $r4s, $r4s_cvg) = split;

    next if ($pdb_id =~ '-' );
    if ( $method eq "rvet") {
	$cvg{$pdb_id} = $rv_cvg;
    } elsif ( $method eq "ivet")  {
	$cvg{$pdb_id} = $iv_cvg;
    } elsif ( $method eq "entr")  {
	$cvg{$pdb_id} = $entr_cvg;
    } elsif ( $method eq "r4s")  {
	$cvg{$pdb_id} = $r4s_cvg;
    } else {
	$cvg{$pdb_id} = $pheno_cvg;
    }
    if ( $reverse ) {
	$cvg{$pdb_id} = 1 - $cvg{$pdb_id};
    }
}



##################################################
# output
format FPTR = 
load @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< , struct_name 
     $pdb_file
zoom complete=1
bg_color white
color white, struct_name
show spheres, struct_name
hide lines, struct_name
#spacefill
.

# open the output file
if  ($reverse ) {
    $filename = $output_file.".rev";
} else {
    $filename = $output_file;
}

open (FPTR, ">$filename") || die "cno $filename\n";

write FPTR;

for $ctr ( 0 .. $#color ) {
    print  FPTR "set_color $color_name[$ctr] = $color[$ctr]\n";
}

foreach $pos ( keys %cvg ) {

    $color_index = int ($cvg{$pos}*$COLOR_RANGE );
    
    print FPTR "color $color_name[$color_index], resid $pos ";
    if ( $chain ){
	print  FPTR  "and chain $chain";
    }
    print  FPTR "\n";
     
}



close FPTR; 





