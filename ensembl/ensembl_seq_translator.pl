#!/usr/bin/perl

#  sample input ( from Ensembl cdNA)
#                R V R  S   R R   Y  KM  R ***VRYSYR       DK   RRY
#   181 GAGGGGCGCGCGGGCAGAACGCGCTCCAGGCCCGGGCCGGCCCGCGCGGCCATGAAGATG    240
#       ...................................................ATGAAGATG      9
#       ...................................................-M--K--M-      3


$sequence = "fam20c.txt";

open(SEQ, "<$sequence") || die "Cno $sequence: $!\n";

$lineno = 0;
$cdna = "";
$cds = "";
$protein = "";
while(<SEQ>) {
    $lineno ++;
    $modulo = $lineno%5;
    $modulo<=1 && next;
    chomp;
    s/[\d ]//g;
    if ($modulo==2) {
        #cDNA
        $cdna .= $_;
    } elsif ($modulo==3) {
        # CDS
        $cds .= $_;
    } elsif ($modulo==4) {
        # protein
        $protein .= $_;
    }

}

@cdna_seq = split "", $cdna;
@cds_seq  = split "", $cds;
@protein_seq = split "", $protein;

$cdna_pos = 239;
$cdna_pos--; # we count from 0
$modulo = $cdna_pos%3;
$codon = substr $protein, $cdna_pos-$modulo, 3;

print "$cdna_seq[$cdna_pos]\n";
print "$cds_seq[$cdna_pos]\n";
print "$codon\n";
