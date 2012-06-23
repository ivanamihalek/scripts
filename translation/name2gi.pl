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
    $key = $aux[1];
    $val = $aux[0];
    #$val = join ('_', @aux[1 .. $#aux]);
    $transl_table{$key} = $val;
}
close TABLE;

#slurp in the input as a single string
open ( FH, "<$translatee" ) ||
    die "Cno $translatee: $!. \n";

undef $/;
$_ = <FH>;
$/ = "\n";

close FH;

foreach $name ( keys %transl_table){
    
    $index =  $transl_table{$name};
    s/($name)/$index/g;
    
}

#print;
#exit;

# ****** MSF SPECIFIC *******
@aux = split ('\n', $_);

for $line ( @aux) {
    if ($line =~ /^\w/) {
	@aux2 = split (' ', $line);
	printf ("%-31s ", $aux2[0] );
	for $i ( 1 .. $#aux2 ) {
	    printf ("%-10s ", $aux2[$i]);
	}
	print "\n";
    } else {
	print "$line\n";
    }
}

print "\n";
