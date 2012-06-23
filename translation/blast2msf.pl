#! /usr/gnu/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
# this format (blasst0 is produced by blas with
# "flat query-anchored without identitites" option
while ( <> ) {
    last if (/ALIGNMENTS/);
}

$first = 1;
$line  = 0;
while ( <> ) {
    next if ( !(/\w/));
    last if ( /Database/);
    $name = substr ( $_, 0, 8);
    next if ( $name =~ '_');
    $aa   = substr ( $_, 13, 60);
    $aa   =~ s/(\s\d+\s*)//;
    $aa   =~ s/(\s)/\./g;
    $aa   =~ s/(-)/\./g;
    if ( ! defined $seq{$name} ) {
	$seq{$name} = "";
	for $ctr ( 1 .. $line*60 ) {
	    $seq{$name} .= ".";
	}
	$seq{$name} .= $aa;
	if ( $first ) {
	    $first = 0;
	    $first_name = $name;
	}
    } else {
	$seq{$name} .= $aa;
	if ($first_name =~ $name) {
	    $line++;
	}
    }
}

$max_length = -1;
foreach $name ( keys %seq) {
    if ( $max_length < length $seq{$name}) {
	$max_length = length $seq{$name};
    }
}

foreach $name ( keys %seq) {
    if (length $seq{$name} < $max_length ) {
	for $ctr ( (length $seq{$name})+1 .. $max_length ) {
	    $seq{$name} .= ".";
	}
    }
}



$no_lines = (int $max_length/50) +1;

#fudge the header
print "PileUp\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf "   MSF:%6d  Type: P    Check:   507   ..\n\n", $max_length;

foreach $name ( keys %seq) {
    print " Name: $name   Len: $max_length\n";
} 
print "\n//\n\n\n";

# output alignment
for $ctr ( 0 .. $no_lines-2) {
    foreach $name ( keys %seq) {
	printf "%-20s %-10s %-10s %-10s %-10s %-10s\n",
	$name,  substr ( $seq{$name}, $ctr*50, 10), 
	substr ( $seq{$name}, $ctr*50+10, 10),
	substr ( $seq{$name}, $ctr*50+20, 10), 
	substr ( $seq{$name}, $ctr*50+30, 10),
	substr ( $seq{$name}, $ctr*50+40, 10);
    }
    print "\n";
}


# the rest:
foreach $name ( keys %seq) {
    printf "%-20s", $name;
    $ctr = ($no_lines-1)*50;
    while ( $ctr+10 < $max_length ) {
	printf " %-10s", substr ( $seq{$name}, $ctr, 10);
	$ctr += 10;
    }
    if ( $ctr < $max_length) {
	print " ", substr ( $seq{$name}, $ctr);
    }
    print "\n";
}
    print "\n";
