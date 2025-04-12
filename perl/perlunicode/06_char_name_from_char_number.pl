#!/usr/bin/env perl
# from https://www.systutorials.com/docs/linux/man/1-perlunicook/#lbAE

 use utf8;      # so literals and identifiers can be in UTF-8
 use v5.12;     # or later to get "unicode_strings" feature
 use strict;    # quote strings, declare variables
 use warnings;  # on by default
 use warnings  qw(FATAL utf8);    # fatalize encoding glitches
 use open      qw(:std :utf8);    # undeclared streams in UTF-8
 use charnames qw(:full :short);  # unneeded in v5.16


use Unicode::Normalize;

# 利 ord: 21033
# hexadecimal 21 033 = 0x5229
print "\x{5229}\n";
print charnames::viacode(0x5229),"\n";
# note the numer is a literal here
print charnames::viacode(21033),"\n";
#Regex:  /\x{1d45b}/
