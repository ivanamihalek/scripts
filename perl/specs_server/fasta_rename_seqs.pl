#!/usr/bin/perl -w
use strict;
use File::Basename;
sub makename;

die ("Usage: fasta_rename <input.afa> <index.afa>  [suffix]") if (@ARGV<2);

open (my $input, "<", $ARGV[0]);
open (my $index, ">>", $ARGV[1]);

my $suffix = "";
defined $ARGV[2] && ($suffix = $ARGV[2]);

my %seen = ();

while (<$input>) {
  next if !/\S/;
  if (/^>/) {
      chomp;
    # in refseq, for example, headers repeat
      my $the_whole_hdr = $_;
      my ($oldname) = /^>([\S^>]+)/;
      my $newname = makename;
      $newname || ($newname = $oldname);
      $newname .= $suffix  if $suffix;
      defined $seen{$newname} || ($seen{$newname} = 0);
      $seen{$newname}  ++;
      if ($seen{$newname} >1 ) {
	  $newname .= "_".$seen{$newname};
      }
      print ">$newname\n";
      print $index "$newname\t$oldname\t$the_whole_hdr\n" if defined $index;
  } else {
      print;
  }
}


sub makename {
    chomp;

    # default
    my $name = "";


    # otherwise
    if (/^>gi\|(\d+)\|\S+/) { # gi
	 my $number = $1;
	if ( /\[(.+?)\]/ ) {
	    my $species = uc join "_", map substr($_,0,3), split(/\s/,$1);
	    $name = "$species\_$number";
	} else {
	    $name = $number;
	}
    } elsif ( /^>lcl\|(\w+)\s/ ) { # fastacmd
	$name=$1;
    } elsif ( /^>tr\|(\w+?)\|/ ) { # trembl
	$name=$1;
    } elsif ( /^>\w*\:([\w\.]+)\s*/ ) { # yeast genomes
	$name=$1;
    } elsif ( /^>.*\|.*\|(\w+?)\s/ ) { # for second name in uniprot
	$name=$1;
    } elsif ( /^>.*ortholog.*\|\s*(\w+)\s*\|/ ) { # for omar
	$name=$1;
    } elsif ( /^>.*\|(\w+?)\s/ ) { # for uniprot names
	$name=$1;
    } elsif ( /^>([\w\d]+?)\// ) { # for Sebastian
	$name=$1;
    } elsif ( /^>.*\|sp\|([\w\d]+?)\|/ ) { # for swissprot names
	$name=$1;
    } elsif ( /^>([\w\d]+?)\s/ ) { # for PDB names
	$name=$1;
    } elsif ( /^>\w+\|\w+[\|\s](\w+)[\|\s]/ ) {
	$name=$1;

    } elsif ( /^>\w+\|\w+[\|\s]\((\w+)\)[\|\s]/ ) {
	$name=$1;
    } elsif ( /^>\s*(\S+)/ ) { # generic
	$name=$1;
    }
}
