#!/usr/bin/env perl
# from https://www.systutorials.com/docs/linux/man/1-perlunicook/#lbAE

 use utf8;      # so literals and identifiers can be in UTF-8
 use v5.12;     # or later to get "unicode_strings" feature
 use strict;    # quote strings, declare variables
 use warnings;  # on by default
 use warnings  qw(FATAL utf8);    # fatalize encoding glitches
 use open      qw(:std :utf8);    # undeclared streams in UTF-8
 use charnames qw(:full :short);  # unneeded in v5.16

 # Always decompose on the way in, then recompose on the way out.
use Unicode::Normalize;

 while (<>) {
     chomp;
     print ">> $_\n";
     # NFD returns the Normalization Form D (formed by canonical decomposition); whatever
     $_ = NFD($_);   # decompose + reorder canonically - this is from Unicode::Normalize
     print  "<< $_\n";
 } continue {
     print NFC($_),"\n";  # recompose (where possible) + reorder canonically
 }
