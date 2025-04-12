#! /usr/gnu/bin/perl

(defined $ARGV[0] && defined $ARGV[1]) || 
    die "usage: access_fix.pl <pdb_name> <decoy_name> \n\n";
$pdb_name = $ARGV[0];
$decoy_name = $ARGV[1];

open (ORIG, "<$pdb_name.pdb") ||
    die "coud not open $pdb_name.pdb\n";
open (DECOY, "<$decoy_name.pdb") ||
    die "coud not open $decoy_name.pdb\n";

$code_old ="BURP";
$orig_seq ="";
$first = 1;
while (<ORIG> ){
    /ATOM(\s)+(\d)+(\s)+(\w)+(\s)+(\D{3})(\s)+(\d+)(\s)+/;
    if ( $first ) {
	$first = 0;
	$orig_offset = $8 - 1;
	print "orig offset: ", $orig_offset, "\n";
    }
    $code = $6;
    if (  $code !~  $code_old) {
	$code_old = $code;
	$orig_seq .= $code;
    }
}
print $orig_seq, "\n";

$code_old ="BURP";
$decoy_seq ="";
while (<DECOY> ){
    /ATOM(\s)+(\d)+(\s)+(\w)+(\s)+(\D{3})(\s)+/;
    $code = $6;
    if (  $code !~  $code_old) {
	$code_old = $code;
	$decoy_seq .= $code;
    }
}
print $decoy_seq, "\n";

if ( $orig_seq =~ $decoy_seq)  {
    $decoy_offset = index ($orig_seq, $decoy_seq)/3;
    print "orig  length: ", (length $orig_seq)/3, "\n";
    print "decoy length: ", (length $decoy_seq)/3, "\n";
    print "decoy offset: ", $decoy_offset, "\n";
} else {
    die "looks like we have a problem: the two sequences do not match.\n";
}

close ORIG;
close DECOY;

$offset = $orig_offset + $decoy_offset;

open (ORIG, "<$pdb_name.pdb") ||
    die "coud not open $pdb_name.pdb\n";
open (DECOY, "<$decoy_name.pdb") ||
    die "coud not open $decoy_name.pdb\n";
open (NEWDECOY, ">$decoy_name.fixed.pdb") ||
    die "coud not open $decoy_name.fixed.pdb\n";


# 123456 789012 34567 89012 34567890 12345678 90123456 78901234 567891 
format NEWDECOY =
@<<<<@#####  @<< @<<<@####    @###.###@###.###@###.###@##.##@##.##
$atom, $ord, $type, $res, $new_label, $x, $y, $z, $a, $b
. 
#ATOM      1  N   GLY     1       1.039   0.374  -0.952  1.00  0.00

    $ord = 0;
while ( <ORIG>  ) {
    ($atom, $aux, $type, $res, $label, $x, $y, $z, $a, $b) = split ;
    $new_label = $label;
    if ( $label - $orig_offset >  $offset) {
	
	last;
    }
    $ord++;
    write NEWDECOY;
}

while ( <DECOY> ) {
    ($atom, $aux, $type, $res, $label, $x, $y, $z, $a, $b) = split ;
    $new_label = $label+$offset+1;
    if ( $atom =~ "ATOM") {
	$ord++;
	write NEWDECOY;
    }
   
}

while ( <ORIG>  ) {
    ($atom, $aux, $type, $res, $new_label, $x, $y, $z, $a, $b) = split ;
    next if  ($aux <= $ord);
    if ( $atom =~ "ATOM") {
	$ord ++;
	write NEWDECOY;
    }
} 



close DECOY;
close NEW_DECOY;

print "\n structure window:  ", $offset+2, ", ",  $offset+(length $decoy_seq)/3+1, "\n";
