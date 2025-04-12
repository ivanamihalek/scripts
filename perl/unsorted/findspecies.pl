#! /usr/bin/perl -w


while (<>) {
    s/\s//g;
    if (!  defined $found {$_} ) {
	$found {$_} = 1;
    }
}

foreach $key (sort(keys %found)) {
    print $key, "\n";
}  
