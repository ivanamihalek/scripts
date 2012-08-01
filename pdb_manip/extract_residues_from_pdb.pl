#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[1]  ) ||
    die "Usage: extract_residues_from_pdb.pl   <pdb file>  <residue list file.\n";
$msf   =  $ARGV[0];
$residues_file =  $ARGV[1];


# readin residues
open ( RES, "<$residues_file") ||
    die "Cno $residues_file: $!\n";

while ( <RES> ) {
    next if ( ! /\S/ );
    next if ( /\#/ );
    chomp;
    @aux = split;
    $pos = $aux[0];
    $pos =~ s/\s//g;
     $selected{$pos} = 1;
}

close RES;


open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

while ( <MSF> ) {

    if ( ! /^ATOM/ && ! /^HETATM/ ) {
	print  ;
	next;
    }

    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;

    $selected{$res_seq} && print ;
}

close MSF;
