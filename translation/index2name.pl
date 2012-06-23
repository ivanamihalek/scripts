#! /usr/gnu/bin/perl -w
# Ivana, 2002
# change all the instances of sequnece index with tax name
# the output is msf specific
$table = "/home/protean5/imihalek/case_studies/bromodomain/nmr/1jm4/seq/db_index2name.table";
open ( TABLE, "<$table") ||
    die "Cno $table: $!\n";

while ( <TABLE>) {
    chomp;
    ($key, $val) = split;
    $transl_table{$key} = $val;
}
close TABLE;

#slurp in the input as a single string
undef $/;
$_ = <>;
$/ = "\n";


foreach $index ( keys %transl_table){
    foreach $i (1..9) {
	$name =  $transl_table{$index};
	$index1 = $index."-$i";
	if ($i > 1) {
	    $name .=".$i";
	}
	s/($index1)/$name/g;
    }
    
}

# ****** MSF SPECIFIC *******
@aux = split ('\n', $_);

for $line ( @aux) {
    if ($line =~ /^\w/) {
	@aux2 = split (' ', $line);
	printf ("%-20s %-10s %-10s %-10s %-10s %-10s\n", @aux2);
    } else {
	print "$line\n";
    }
}
