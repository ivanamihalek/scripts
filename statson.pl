#! /usr/bin/perl -w

$column = 6;
$i = 0;
<>;
while ( <>) {
    chomp;
    @aux = split;
    $val[$i] =  $aux[$column];
    $name[$i] =  $aux[0];
    $i++;
}

$avg = 0;
foreach $i ( 0 .. $#val) {
    $avg += $val[$i];
}
$avg /= ($#val+1);
$ref = $val[$#val];

$max = -50;
$min = 50;
$ctr = 0;
foreach $i ( 0 .. $#val) {

    if (  $val[$i] > $max ) {
	$max = $val[$i];
	$max_name = $name[$i];
    }elsif (  $val[$i] < $min ) {
	$min = $val[$i];
	$min_name = $name[$i];
    }
    $aux = $avg - $val[$i];
    $std_dev += $aux*$aux;
    if ( $val[$i] >= $ref ) {
	$ctr++;
    }
}
$std_dev /= ($#val+1);
$std_dev  = sqrt($std_dev);

printf "\n avg: %12.4e  std_dev: %12.4e  max: %12.4e z: %12.4e\n",
	 $avg, $std_dev,$max, ($max-$min)/$std_dev;
printf " native in the upper %d%% \n\n", $ctr/($#val+1)*100;
printf " min: $min ($min_name) \n max: $max ($max_name)\n\n";
