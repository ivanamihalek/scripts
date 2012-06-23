#! /usr/gnu/bin/perl -w

while ( <> ) {
    last if (/Rank/);
}
$sum1 = 0;
$sum2 = 0;
while ( <> ) {
    last if (/not done/);
    chomp;
    @aux = split;
    $sum1 += $aux[7];
    if ($aux[8]){
	$sum2 += -log($aux[8]);
    }else {
	$sum2 += 6;
    }
}
printf ("%10d  %10.2e\n", $sum1, $sum2);
