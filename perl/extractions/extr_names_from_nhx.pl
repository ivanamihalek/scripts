#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
undef $/;
$_ = <>;
$/ = "\n";

print "$1\n"  while /([\w\-]{4,})\:/gc;
