#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
=pod
@aachar = (  "A",  "R",   "N" ,  "D" ,  "C" ,  "Q" ,  "E" ,
     "G",   "H",   "I",   "L",   "K",   "M" ,  "F" ,  "P",
      "S",   "T",   "W ",  "Y",   "V" ); 
=cut
while ( <> ) {
    last if (/A      R      N      D      C      Q      E      G/);
}

$line = 0;
while ( <> ) {
    last if (/A     R     N     D     C     Q     E     G     H/);
    chomp;
    @aux = split;
    for ($col = 0; $col< $line; $col++ ) {
	$freq[$line][$col] = $aux[$col]/2; #using blosum*.out - off diag elmts are doubled
	$freq[$col][$line] = $aux[$col]/2;
    }
    $freq[$col][$col] = $aux[$col];
    $line ++;
}


for ($col = 0; $col<20; $col++ ) {
    $subsum[$col] = 0;
}
for ($col = 0; $col<20; $col++ ) {
    for ($line = 0; $line <20; $line++ ) {
	$subsum[$col] +=  $freq[$line][$col];
    }
}


for ($line = 0; $line <20; $line++ ) {
    for ($col = 0; $col<=$line; $col++ ) {
	$freq[$line][$col] /= $subsum[$col];
	$freq[$col][$line]  = $freq[$line][$col];
	printf "%8.4f ", $freq[$line][$col];
    }
    print "\n";
}


=pod
for ($line = 0; $line <20; $line++ ) {
    $subsum[$line] = 0;
    for ($col = 0; $col<20; $col++ ) {
	$subsum[$line] += $freq[$line][$col];
    }
    printf "%4d  %8.4f \n", $line, $subsum[$line];
}
=cut
