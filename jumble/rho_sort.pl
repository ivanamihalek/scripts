#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

while ( <> ) {
    next if (/^\%/ );
    next if ( ! (/\w/) );
    @aux = split;
    if (defined  $lines{$aux[6]} ) {
	$lines{$aux[6]} .= $_;
    } else {
	$lines{$aux[6]} = $_;
    }
}

foreach $rho ( keys %lines ) {
    if ( ($lines{$rho} =~  s/\n/\n/g ) > 1 ) {
	print $lines{$rho}, "\n";
    }
}
