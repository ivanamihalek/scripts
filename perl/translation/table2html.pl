#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

print "{| width=\"200\" cellspacing=\"1\" ".
    " cellpadding=\"1\" border=\"1\" align=\"right\" \n";
while ( <IF> ) {
    chomp;
    @aux = split;
    print "|-\n";
    foreach (@aux) {
	print "| $_\n";
    }
}
print "|}\n";

close IF;
