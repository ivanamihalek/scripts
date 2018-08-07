#!/usr/bin/env perl
# from https://www.systutorials.com/docs/linux/man/1-perlunicook/#lbAE

 use utf8;      # so literals and identifiers can be in UTF-8
 use v5.12;     # or later to get "unicode_strings" feature
 use strict;    # quote strings, declare variables
 use warnings;  # on by default
 use warnings  qw(FATAL utf8);    # fatalize encoding glitches
 use open      qw(:std :utf8);    # undeclared streams in UTF-8
 use charnames qw(:full :short);  # unneeded in v5.16

 # In an interpolated literal, whether a double-quoted string or a regex,
 # you may specify a character by its number using the "\x{HHHHHH}" escape
use Unicode::Normalize;

#String: "\x{1d45b}"
# this has to be hexadecimal - or returns decimal

# 利 ord: 21033
# hexadecimal 21 033 = 0x5229
print "wrong: decimal \x{21033}\n";
print "right: \x{5229}\n";
print "\n";

#不 ord: 19981
# 19981 = 0x4E0D
print "wrong: decimal \x{19981}\n";
print "right: \x{4E0D}\n";
print "\n";
