#! /usr/bin/perl -w

@ARGV>0 || die "Usage: $0 <tex filename>.\n";


$fnm = $ARGV[0];

$intxt =  `cat $fnm`;

$intxt =~ s/^\s*//;
$intxt =~ s/[ ]*([\.\,\;])/$1/g;

$intxt =~ s/\n\n+/PARAGRAPH/g;
$intxt =~ s/\s+/ /g;

$intxt =~ s/PARAGRAPH/\n\n/g;
print $intxt, "\n";

