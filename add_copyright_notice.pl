#! /usr/bin/perl -w

@ARGV>=3 ||
    die "Usage:  $0  <file name> <after line no> <copyrigt text file> \n";

($filename,  $lineno, $cptxt) = @ARGV;

open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

open (OF, ">tmp_tmp") ||
    die  "Cno tmp_tmp: $!.\n";

$line_ct = 1;
while ( <IF> ) {
    print OF;
    if ($line_ct == $lineno) {
	$ret =   `cat $cptxt`;
	print OF $ret;
    }
    $line_ct ++;
}
close OF;
close IF;

`mv tmp_tmp  $filename`;
