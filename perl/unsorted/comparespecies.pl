#! /usr/gnu/bin/perl -w

defined $ARGV[0] && defined $ARGV[1] ||
    die "Usage: comparespecies.pl <file1> <file2>.\n";

open (FILE1,"<$ARGV[0]") || 
    die "no file";

open (FILE2,"<$ARGV[1]") || 
    die "no file";

# read one file as a single string
undef $/;
$names = <FILE1>;
$/ = "\n";


while (<FILE2>) {
    
    chomp ;
    @aux = split;
    if (  $names =~ $aux[0] ) {
	print "$_ \n";
    } else {
	# print "$_ \n";
    }

}
