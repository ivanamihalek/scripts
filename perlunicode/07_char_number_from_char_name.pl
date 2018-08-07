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

#不 ord: 19981
# 19981 = 0x4E0D
print "\x{4E0D}\n";
print charnames::viacode(0x4E0D),"\n";
print charnames::vianame("CJK UNIFIED IDEOGRAPH-4E0D"),"\n";
# to interpolate (note no quotes in {})
print "\N{CJK UNIFIED IDEOGRAPH-4E0D}\n";
# here's a confusing point:
# (this is also 不)
print "\x{F967}\n";
print charnames::viacode(0xF967),"\n";
