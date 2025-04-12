package testlib;
use strict;
use warnings FATAL => 'all';

our $somevar = "i am somevar";
our %toolLocations =
    (
     "bcftools"     => "bcftools-TOOL_VERSION/bcftools",
     "bedtools"     => "bedtools2/bin/bedtools",
     "bamclipper"   => "bamclipper-TOOL_VERSION/bamclipper.sh",
     "bwa"          => "bwa-TOOL_VERSION/bwa",
    );

1;
