#! /usr/gnu/bin/perl -w
# Ivana, 2002
# change all the instances of sequnece index with tax name
# the output is msf specific
defined $ARGV[0] &&  defined $ARGV[1] ||
    die "Usage: gi2name.pl <table_file_name> <translatee_name>.\n"; 
$table = $ARGV[0]; 
$translatee =  $ARGV[1]; 
open ( TABLE, "<$table") ||
    die "Cno $table: $!\n";

while ( <TABLE>) {
    chomp;

    @aux = split;
    $key = $aux[0];
    $val = join ('_', @aux[1 .. $#aux]);
    $transl_table{$key} = $val;
}
close TABLE;

#slurp in the input as a single string
open ( FH, "<$translatee" ) ||
    die "Cno $translatee: $!. \n";
while ( <FH> ) {
    @aux = split;
    $key = $aux[0];
    print "$key  ";
    if  ( defined $transl_table{$key}  ) {
	print "$transl_table{$key}";
    }
    print "\n";
}

close FH;
