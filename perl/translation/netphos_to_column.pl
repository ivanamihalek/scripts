#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";
($kw, $pos, $seq, $score, $pred) = ();
$max_pos = -50;
while ( <IF> ) {
    next if ( ! /^Sequence/ );
    chomp;
    ($kw, $pos, $seq, $score, $pred) = split;
    $res_type = substr $seq, 4, 1;
    if ( $res_type eq "S" ) {
	$serine{$pos} = $score;
    } elsif ( $res_type eq "T" )  {
	$threonine{$pos} = $score;
    } elsif ( $res_type eq "Y" )   {
	$tyrosine {$pos} = $score;
    } else {
	die "oink? $_\n";
    }
    ($max_pos < $pos) && ($max_pos = $pos) ;

}

close IF;

for $pos ( 1 .. $max_pos) {
    if ( defined $serine{$pos}) {
	$annot = sprintf " pS  %4.2f",$serine{$pos};
    } elsif  ( defined $threonine{$pos} ) {
	$annot = sprintf " pT  %4.2f",$threonine{$pos};
    } elsif  ( defined $tyrosine {$pos}) {
	$annot = sprintf " pY  %4.2f",$tyrosine{$pos};
   } else  {
	$annot = "";
    }
    print " $pos \t $annot\n";
}
