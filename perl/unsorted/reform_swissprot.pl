#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
sub output;

$reading = 0;
while ( <> ) {
    if ( /^AC/ ) {
	chomp;
	$namestr = substr $_, 5;
    } elsif (/^DR/ ) {
	chomp;
	$namestr .= substr $_, 5;
    } elsif (/^SQ/ ) {
	$reading = 1;
	$seq = "";
    } elsif ( /^\/\// ) {
	$reading = 0;
	output ();
    } elsif ( $reading ) {
	$seq .= $_;
    }


}


sub output () {
    $namestr =~ s/\s//g;
    print "> $namestr\n";
    print $seq;
}
