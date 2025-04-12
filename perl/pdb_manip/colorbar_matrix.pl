#!/usr/bin/perl -w

$WIDTH = 50;
$HEIGHT = 1600;
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
$color[0] = "$red  $green  $blue"; 

for ( $ctr=1; $ctr <= int ($COLOR_RANGE/$N); $ctr++ ) {

    $ratio = ($C1/$N-($ctr-1))/($C1/$N);
    $red   = int ( $ratio * 254);
    $green = $blue = 0;
		 
    $color[$ctr] = "$red  $green  $blue"; 

}

for ( $ctr= int ($COLOR_RANGE/$N)+1 ; $ctr <= $COLOR_RANGE; $ctr++ ) {

    $ratio =  ( $ctr -  $COLOR_RANGE/$N)/ ($COLOR_RANGE*($N-1)/$N);
    $red = int ( $ratio * 254);
    $green = $blue = $red;
		 
    $color[$ctr] = "$red  $green  $blue"; 

}
open ( OF, ">tmp" ) || di e"Cno tmp: $!.\n";

print  OF  "P3\n";
print  OF  "# colorbar\n";
print  OF  "$WIDTH  $HEIGHT\n";
print  OF "255\n";

for ( $ctr=0; $ctr <= $COLOR_RANGE; $ctr++ ) {
    foreach $y ( 1 .. $HEIGHT/$COLOR_RANGE) {
	foreach $x ( 1 .. $WIDTH ) {
	    print   OF  "$color[$ctr] \n";
	}
    }

}
close OF;

`ppmtogif tmp > colorbar.gif`;
`rm tmp`;
