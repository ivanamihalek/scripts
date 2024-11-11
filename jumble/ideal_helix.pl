#!/usr/bin/perl -w

use Math::Trig;

$c = 1.5;
$r = 2.3;
$pi =  3.14159265;

$alpha = 100/180*$pi;
printf  "alpha = %6.2f\n", $alpha/$pi*180;


$t12 = 2*$r*sin($alpha/2);
printf  "t12 = %6.2f\n", $t12;

$d12 = sqrt ($t12**2+$c**2);
printf  "d12 = %6.2f\n\n", $d12;

$t13 = 2*$r*sin( (2*$pi-2*$alpha)/2);
printf  "t13 = %6.2f\n", $t13;

$d13 = sqrt ($t13**2+(2*$c)**2);
printf  "d13 = %6.2f\n\n", $d13;




$t14 = 2*$r*sin( (2*$pi-3*$alpha)/2);
printf  "t14 = %6.2f\n", $t14;

$d14 = sqrt ($t14**2+(3*$c)**2);
printf  "d14 = %6.2f\n\n", $d14;



$t15 = 2*$r*sin( (-2*$pi+4*$alpha)/2);
printf  "t15 = %6.2f\n", $t15;

$d15 = sqrt ($t15**2+(4*$c)**2);
printf  "d15 = %6.2f\n\n", $d15;
