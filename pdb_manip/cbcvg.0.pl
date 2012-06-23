#!/usr/bin/perl -w

(defined $ARGV[0] && defined $ARGV[1]) ||
    die "Usage:  cbcvg.pl <epitope_file> <ranks_sorted_file>  <pdb_file_full_path> [<chainname>]\n"; 
 


##################################################
#set the pallette:
$COLOR_RANGE = 32;
$PI = atan2 (0,-1);
$green = $blue = $red = 0;

=pod
for ( $ctr=0; $ctr <=$COLOR_RANGE; $ctr++ ) {
    $red = 254;
    $ratio =  $ctr/$COLOR_RANGE;
    $green = $blue =int (sin ($ratio*$PI/2)*254);
    $green = $blue =int (exp($ratio)/exp(1)*254);
}
=cut 

$N = 8;
for ( $ctr=0; $ctr <= int ($COLOR_RANGE/$N/2); $ctr++ ) {

    $ratio =  ($COLOR_RANGE/$N/2-$ctr)/($COLOR_RANGE/$N/2);
    $red = int ( $ratio * 254);
    $green = $blue = 0;
		 
    $color[$ctr] = "[$red, $green, $blue]"; 
}
for ( $ctr= int ($COLOR_RANGE/$N/2); $ctr <= int ($COLOR_RANGE/$N); $ctr++ ) {

    $ratio =  ($ctr - $COLOR_RANGE/$N/2)/($COLOR_RANGE/$N/2);
    $red = 254;
    $green = int ( $ratio * 254);
    $blue = 0;
		 
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
=cut

##################################################
# input
$epi_file   = $ARGV[0];
$ranks_file = $ARGV[1]; 
$pdb_file   = $ARGV[2]; 

if ( defined $ARGV[3] && $ARGV[3] =~ /\-s/ ) {
    $spacefill = 1;
}

open ( EPI_FILE, "<$epi_file") || 
    die "cno $epi_file\n";

@epitope = ();
while (<EPI_FILE>) {
    if ( /\S/ ) {
	chomp;
	$aux = $_;
	$aux =~ s/\s//g;
	push @epitope, $aux;
    }

}


open (RANKS_FILE, "<$ranks_file") || 
    die "cno $ranks_file\n";

while ( <RANKS_FILE> ) {
    next if ( !/\S/ );
    next if ( /\%/ );
    chomp;
    @aux = split;
    $pdb_id = $aux[1];
    next if ($pdb_id =~ '-' );
    foreach $pos ( @epitope ) {
	if ($pos =~ $pdb_id) {
	    $cvg{$pos} = pop @aux;
	    last;
	}
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
.

# open the output file
if ( $spacefill ) {
    $filename = "$ranks_file.sf.rs";
} else {
    $filename = "$ranks_file.rs";
}
open (FPTR, ">$filename") || die "cno $filename\n";
write FPTR ;

foreach $pos ( @epitope ) {
    $color_index = int ($cvg{$pos}*$COLOR_RANGE);
    print FPTR "\n";
    print FPTR "select  $pos \n";
    if ( $spacefill ) {
	print FPTR "spacefill\n";
    }
    print FPTR "color $color[$color_index] \n";
    
}


close FPTR;

