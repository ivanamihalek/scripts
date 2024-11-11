#!/usr/bin/perl -w



$player_dir = "/media/MP3_";

( -e $player_dir ) || die "Cannot find $player_dir\n";

$music = "music";
$intermediate = "intermediate";
$elementary = "elementary";
$newbie = "newbie";
$jap    = "Japanese";
$qingwen = "qingwen";

@channel = ($music, $intermediate, $elementary, $newbie, $qingwen, $jap);

 @prob   = (15,     3,             15,            10,       0.5,   3);

$norm = 0;
foreach ( @prob ) {
    $norm += $_;
}

for $i (0 .. $#prob) {
    $prob[$i] /= $norm;
}

printf  "%5.2f %5.2f %5.2f %5.2f %5.2f %5.2f  \n", @prob ;

for $i (1 .. $#prob) {
    $prob[$i] += $prob[$i-1];
}

printf  "%5.2f %5.2f %5.2f %5.2f %5.2f %5.2f  \n", @prob ;

#exit;

foreach $dir (@channel) {
    ( -e "available/$dir" ) || 
	die "Cannot find available/$dir\n";
    @{$names{$dir}} = split "\n", `ls available/$dir/*.mp3`;
}


$outfile =  "to_copy.sh";
open ( OF, ">$outfile") ||
    die "Cno $outfile:$!\n";
    
print OF  "#!/bin/sh\n";


$ctr = 9;
$prev_dir = "";
%used = ();

while ($ctr <= 50) {

    $done = 0;
    while ( ! $done)  {
	$random = rand(1);
	for $cct ( 0 .. $#prob) {
	    if ( $random <= $prob[$cct] ) {
		$dir = $channel[$cct];
		if ( $dir ne $prev_dir ) {
		    $prev_dir = $dir;
		    $done = 1;
		}
		last;
	    }
	}
    }

    $list_length = $#{$names{$dir}};
    $dumbo = 0;
    do {
	$random = rand ($list_length);
	$item = $names{$dir}[$random];

	( defined $item ) || 
	    die "not defined names for $dir $random\n".
	    "list length:  $list_length \n";
	$dumbo++;
    } while  ( defined $used{$item} && $dumbo < 100);
    ($dumbo ==100) && next;

    $used{$item} = 1;
    $ctr ++;

    if ( $ctr < 10 ) {
	$padded = "00$ctr";
    } elsif ( $ctr < 100 ) {
	$padded = "0$ctr";
    } else {
	$padded = "$ctr";
	
    }
    @aux = split "/", $item;
    $name = pop @aux;
    $newname = join "_", (split " ", $name);
    $newname =~ s/[-\'\,\;\&]//g;
    $newname =~ s/__/_/g;

    $name = quotemeta $name;
    push @aux, $name;
    $item = join "/", @aux;
    #print "available/$dir/$item   $padded\_$newname\n";
    print "$dir  $padded\_$newname\n";
    print OF "cp  $item   $player_dir/$padded\_$newname\n";

}

close OF;
`chmod uog+x $outfile`;
