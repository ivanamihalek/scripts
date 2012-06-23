#! /usr/bin/perl -w
# this is not rally workin
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined $ARGV[0] ) ||
    die "Usage: lin2matrix.pl <linear pattern file>.\n";

$filename = $ARGV[0];
open ( IF, "<$filename") || die "Cno $filename: $!.\n";
undef $/;
$_ = <IF>;
$/ = "\n";
close IF;

@lines = split '\n', $_;

$linctr = 0;
foreach ( @lines) {
    $linctr++;
    chomp;
    @aux = split '';
    $bitctr = 0;
    foreach $bit ( @aux) {
	$bitctr++;
	printf "%5d  %5d   %1d \n",  $linctr, $bitctr, $bit;
    }
}



