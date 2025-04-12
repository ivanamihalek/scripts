#!/usr/bin/perl
use feature qw(say);
use File::Temp qw/ tempfile tempdir /;

my ($tmpFile, $tmpFileName) = tempfile("." . "/XXXXX");
say($tmpFileName);

0;
