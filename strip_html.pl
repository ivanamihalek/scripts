#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

undef $/;
$_ = <>;

    $blah = $_;
    $blah =~ s/\<.+?\>/ /g;
    $blah =~ s/\&gt\;/\>/g;
    $blah =~ s/\&gt\;/\>/g;
    $blah =~ s/\&nbsp\;//g;
    $blah =~ s/\&nbs//g;
    $blah =~ s/\n/@/g;
    $blah =~ s/\<.+?\>/ /g;

@lines = split '@', $blah;
foreach $line (@lines ) {
    next if ( $line !~ /\S/ );
    print "$line\n";
}
    

