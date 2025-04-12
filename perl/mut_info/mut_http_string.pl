#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

@aux = ();
while ( <> ) {

$blah = $_;
$blah =~ s/\"//g;
$blah =~ s/\<\/pre\>//g;
$blah =~ s/\<pre\>//g;
    $blah =~ s/\<a//g;
    $blah =~ s/\/a\>/  /g;
    $blah =~ s/\>\w\</  /g;
    $blah =~ s/HREF=/\n/g;

    print $blah;
    @aux  = split  ('\n', $blah);
}   

