#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Cwd;

my $homedir = Cwd::abs_path($0) =~ /^(.*)\// ? $1 : "";
if (defined $homedir && $homedir) {
	push(@INC, "$homedir/../common_scripts");
}
require testlib;
print($testlib::somevar, "\n");
$testlib::somevar = "now I am something else";
print($testlib::somevar, "\n");

print($testlib::toolLocations{"bwa"}, "\n");
