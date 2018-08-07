#!/usr/bin/env perl
# from https://www.systutorials.com/docs/linux/man/1-perlunicook/#lbAE

 use utf8;      # so literals and identifiers can be in UTF-8
 use v5.12;     # or later to get "unicode_strings" feature
 use strict;    # quote strings, declare variables
 use warnings;  # on by default
 use warnings  qw(FATAL utf8);    # fatalize encoding glitches
 use open      qw(:std :utf8);    # undeclared streams in UTF-8
 use charnames qw(:full :short);  # unneeded in v5.16

 # The "ord" and "chr" functions work transparently on all codepoints,
 #not just on ASCII alone X nor in fact, not even just on Unicode alone.
use Unicode::Normalize;

 while (<>) {
     chomp;
     # NFD returns the Normalization Form D (formed by canonical decomposition); whatever
     $_ = NFD($_);   # decompose + reorder canonically - this is from Unicode::Normalize
     print NFC($_);
     my $ord = ord($_);
     print "ord: ", $ord,"\n";
     print "back: ", chr($ord),"\n\n";

 }
