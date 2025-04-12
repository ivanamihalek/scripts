#! /usr/gnu/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[0]  ||
    die "Usage: msf2gif.pl  <base_name>.\n"; 

$base_name = $ARGV[0];
$msf       = "$base_name.msf";

open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

# read in the msf file:
while ( <MSF> ) {
    last if ( /\/\//);
}

%sequence = ();
do {
    if ( /\w/ ) {
	@aux = split;
	$name = $aux[0];
	$aux_str = join ('', @aux[1 .. $#aux] );
	if ( defined $sequence{$name} ) {
	    $sequence{$name} .= $aux_str;
	} else {
	    $sequence{$name}  = $aux_str;
	}
		
    } 
} while ( <MSF>);




# turn the msf into a table (first index= sequence, 2nd index= position)

$seq = 0;
foreach $name ( keys %sequence ) {
    @aux = split '', $sequence{$name};
    $max_pos = $#aux;  # max index a position can have
   foreach $pos ( 0 .. $#aux ) {
	$array[$seq][$pos] = $aux[$pos];
    }
    $names[$seq] = $name;
    $seq++;
    
}
$no_seqs = $seq;   # number of seqs
$max_seq = $seq-1; # max index a seq can have

# sanity check:
$no_seqs || die "Error msf2gif.pl: no seqs found.\n"; 

# assign color to each amino acid
# white for gaps
$color{'.'} = "255    255   255";
# black to greyish-green  F, Y, W
$color{'W'} = "0    0    0";
$color{'Y'} = " 85  85  85";
$color{'F'} = "191 191  191"; 
# dark green C
$color{'C'} = " 50   50  0";
# dirty yellow M
$color{'M'} = "125  125  0";
# yellow V, I, L
$color {'V'} = "255 255  255 ";
$color {'L'} = "255 212    0 ";
$color {'I'} = "255 205    0 ";
# orange A
$color {'A'} = "255 170  0 ";
# bright red P
$color {'P'} = "255  0   0 ";
# dull    G
$color {'G'} = "130  0   0 ";
# purple S,T
$color {'S'} = "255  0   255 ";
$color {'T'} = "212  0   255 ";
# dark blue N, Q
$color {'N'} = "125  0   255 ";
$color {'Q'} = " 50  0   255 ";
# light blue D,E
$color {'D'} = "125  125  255 ";
$color {'E'} = "  0  255  255 ";
# blue-green K,R, H
$color {'K'} = "125 255  125 ";
$color {'R'} = " 85 255   85 ";
$color {'H'} = " 0 255  0"; 


open (PPM, ">tmp.ppm") ||
    die "Cno tmp.ppm: $!.\n";

printf PPM "P6\n";
printf PPM "# created by msf2gif\n";
printf PPM " %d  %d  \n", ($max_pos+1)*10, $no_seqs ;
printf PPM "255\n";
close PPM;

open (PPM, ">>tmp.ppm") ||
    die "Cno tmp.ppm for appending: $!.\n";


for $s (0 .. $max_seq) {
    for $i (0 .. $max_pos) {
	for $rep (1 .. 10 ) {
	   
	   	printf PPM  "  $color{'.'} \n"
	}
    } 
} 



close PPM; 
