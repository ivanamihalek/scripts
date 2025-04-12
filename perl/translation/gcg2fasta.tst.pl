#! /usr/gnu/bin/perl

use Bio::AlignIO;

  $in  = Bio::AlignIO->new('-file' => "4fgf.input" ,
                           '-format' => 'fasta');
  $out = Bio::AlignIO->new('-file' => ">test.msf",
                           '-format' => 'clustalw');
  while ( my $aln = $in->next_aln() ) { $out->write_aln($aln); }
