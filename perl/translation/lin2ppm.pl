#! /usr/bin/perl -w
# this is not rally workin
use IO::Handle;         #autoflush
# FH -> autoflush(1);


@zero_color = pack ("c3", 0, 0, 0); # back three numerical values into bytes
@one_color = pack ( "c3", 125, 0, 0);

$filename = "test.lin";
open ( IF, "<$filename") || die "Cno $filename: $!.\n";
undef $/;
$_ = <IF>;
$/ = "\n";
close IF;

@lines = split '\n', $_;
$width = length ( $lines[0]);
$height = $#lines + 1;

$filename = "test.ppm";
open ( OF, ">$filename") || die "Cno $filename: $!.\n";
binmode OF;

print OF "P6\n";
print OF "$width  $height\n";
print OF "255\n";


foreach ( @lines) {
    chomp;
    @aux = split '';
    foreach $bit ( @aux) {
	if ( $bit ) {
	    print OF @zero_color;
	} else {
	    print OF @one_color;
	}
    }
}


close OF;
