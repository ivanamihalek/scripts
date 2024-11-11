#! /usr/gnu/bin/perl

$ctr = 0;
while (<>) {
    chomp;
    while ( $_ =~/\./ ) {
	$ctr++;
        s/\./X/ ;
    }
    print $_, "\n";
}
print $ctr, "\n";
