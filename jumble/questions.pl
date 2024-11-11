#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);


@first = ("Starting from", "Knowing", "Considering", "Using", "Averaged over", "Applying statistical information about",
 "In statistically general terms of");

@second = ("the immediate neighborhood on the sequence", "secondary structure information", 
"three-dimesional structure", "evolutionary pressure",  "phylogenetic contribution", "top ranking residues",
  "bottom ranking residues", "the number of hydrogen bonds", "the fold or superfamily", 
 "correlation between speciation and mutation events", "significant cluster size", "spatial distribution of important residues",
 "surface distribution of important residues", "fold propensity", "amino-acid type of trace residues","overall protein size", 
"protein function", "subcellular localization", "a measure of alignment diversity", "a measure of alignment quality",
"charge distribution", "contacts between spatially adjacent residues", "solvent accesibility", 
 "cluster excentricty, mass distribution, and other shape indicators", "average residue polarity", "average residue charge"); 

@third = ("what is the probability of", "what is the frequency of",  "analyze variability of", 
"what is the statistical inference about",  "what are the physico-chemical properties of" , "determine correlations in", "find  distribution of", 
 "determine the statistical significance of", "what is the implication it bears on");

srand (time ^ $$ );
$l = -1;
for $i ( 1 .. 30) {
    $f = int (rand ($#first+1));
    $s = int (rand ($#second+1));
    $t = int (rand ($#third+1));
    $l = $s;
    while ( $l == $s ) {
	$l =  int (rand ($#second+1));
    }
    printf "%5d:", $i;
    print "   $first[$f] $second[$s],\n\t $third[$t] $second[$l].\n";
}
