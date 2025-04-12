#! /usr/bin/perl -w

%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
		 'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
		 'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
		 'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E', 
		 'PTR', 'Y', 'MSE', 'M' ); 

@ARGV || die "Usage: $0 <footprint> <epi (output)>\n";

($in_foot, $out_epi) = @ARGV;

($pdbid, $dist, $type) = ();

open ( IF, "<$in_foot") || die "Cno $in_foot: $!.\n";
open ( OF, ">$out_epi") || die  "Cno $out_epi: $!.\n";

while  ( <IF> ) {
    next if ( !/\S/ );
    next if ( /^\#/ );
    chomp;
    ($pdbid, $dist, $type) = split;
    $type = $letter_code{$type};
    print  OF   "$pdbid  $type \n";
}

close IF;
close OF;
