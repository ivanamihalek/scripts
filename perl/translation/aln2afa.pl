#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];

($root) = split '\.', $filename;
($name[1], $kw,  $name[0]) = split "_", $root;



open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

$seq[0] = "";
$seq[1] = "";

$flip =0;
while ( <IF> ) {
    chomp;
    @aux = split;
    shift @aux; # get rid of the comment sign
    (scalar @aux) || next;
    $kw = shift @aux;
    ($kw eq "distances") && last;
    (scalar @aux) || next;
    ($aux[0] =~ /\w/ )  || next;
    $seq[$flip] .= $aux[0]."\n";
    $flip = 1 - $flip;
}

close IF;

for $i ( 0 .. 1) {
    $seq[$i] =~ s/\./\-/g ;
    print ">$name[$i]\n";
    print "$seq[$i]";

}
