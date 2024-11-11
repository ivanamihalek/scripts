#!/usr/bin/perl

while (<>) {
    if (!/\d/) {
 	print;
    } else {
	$line = $_;
	while ($line =~ /(\d\.\d+)/ )  {
	    $rounded = sprintf "%d", $1;
	    $line =~ s/$1/$rounded/;
	}
	print $line;
    } 
}
print "\n";
