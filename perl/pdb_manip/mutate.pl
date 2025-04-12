#! /usr/bin/perl -w
# read in PDB file and a seqeunce
# delete all the sidechains, keeping Cbravo's only
# where possible and appropriate, and replace the name by the name from the 
# sequence

use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined $ARGV[1] ) ||
    die "Usage: mutate.pl  <pdbfile> <mutation list>.\n\tmutation list:  pdbid  new_aa_type\n(aa_type given as single letter)";
# mutation list:  pdbid  new_aa_type

$pdbfile =  $ARGV[0];
$mutfile =  $ARGV[1];


$filename = $mutfile;
open ( IF, "<$filename" ) || die "Cno $filename: $!.\n";
while ( <IF> ) {
    next if ( ! /\S/ ) ;
    chomp;
    @aux = split;
    $mutation{$aux[0]} = $aux[1];
}
close IF;



%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
           'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
           'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
               'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E');
foreach  $tri ( keys %letter_code  ) {
    $letter2three{ $letter_code{$tri} } = $tri;
}

@backbone = ("N", "CA", "C", "O", "CB");

# output the pdb:
# if new and old type are the same, keep everything
#  deleting everything but cbravo
# if new identity GLY, skip Cbravo too
# use new id as type ...
$filename = $pdbfile;
open ( IF, "<$filename" ) || die "Cno $filename: $!.\n";



while ( <IF> ) {

    if ( ! /^ATOM/ ) {
	print ;
	next;
    }
    $name = substr $_,  12, 4;     $name =~ s/\s//g; 
    $name =~ s/\*//g; 
    $alt_loc = substr $_,16, 1;    $alt_loc =~ s/\s//g;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
    if ( ! defined $mutation{$res_seq} || $mutation{$res_seq} eq $letter_code{$res_name}) {
	print ;
	next;
    }
    next if ( $alt_loc =~ "B" );
    $newline = $_;
    substr ($newline,16, 1 ) = " "; # alt loc

    $newtype = $mutation{$res_seq};
    if ( $newtype eq $letter_code{$res_name} ) {
	print $newline;
	next;
    }
    foreach $bb_atom ( @backbone ) {
	last if ( $newtype eq "G" &&  $bb_atom eq "CB");
	if ( $name eq  $bb_atom  ) {
	    if ( ! defined $letter2three{$newtype} ) {
		print " *  $res_seq   $newtype  -- aa type not recognized (single letter code expected)* \n";
		exit;
	    }
	    substr( $newline,  17, 3) = $letter2three{$newtype};
	    print $newline;
	    last;
	}
    }
    
}
close IF;
