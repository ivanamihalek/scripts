#! /usr/bin/perl -w

$detex = "/usr/bin/detex";

(-e $detex) || die "$detex not found.\n";

@ARGV>0 || die "Usage: $0 <tex filename>.\n";


$fnm = $ARGV[0];

$intxt =  `$detex $fnm`;

$intxt =~ s/^\s*//;
$intxt =~ s/[ ]*([\.\,\;])/$1/g;

$intxt =~ s/\n\n+/PARAGRAPH/g;
$intxt =~ s/\s+/ /g;

$intxt =~ s/PARAGRAPH/\n\n/g;
print $intxt, "\n";
