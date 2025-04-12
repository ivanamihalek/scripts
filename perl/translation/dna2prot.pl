#! /usr/bin/perl  


use IO::Handle;         #autoflush
# FH -> autoflush(1);

sub initialize_genetic_code;

defined ($ARGV[0] ) || 
    die "Usage: dna2prot.pl <input file> ".
    "[-table <genetic code table number>] [-shift <frameshift>] [-fancy] .\n"; 

$if_name = $ARGV[0];

$table_no = 1;
$frameshift = 0;
$fancy = 0;
if ( @ARGV > 1) {
    shift @ARGV;
    while ( @ARGV ) {
	$kwd = shift  @ARGV;
	if ( $kwd =~ /table/ ) {
	    $table_no = shift  @ARGV;
	} elsif ( $kwd =~ /shift/ ) {
	    $frameshift = shift  @ARGV;
	} elsif ( $kwd =~ /fancy/ ) {
	    $fancy = 1;
	}
    }
}
( $frameshift <0  ) && ( $frameshift = 2);


initialize_genetic_code ( $table_no); 
@aas = split '', $AAs;
@starts = split '', $Starts;
@base1 = split '', $Base1;
@base2 = split '', $Base2;
@base3 = split '', $Base3;

for $i (0..$#aas) {
    $codon= $base1[$i]. $base2[$i]. $base3[$i];
    $translation{$codon} = $aas[$i];
    #print "$i  ***  $aas[$i]  ***   $codon  *** ", $translation{$codon}, "  ***\n";
}


$dna_str = "";
$seqname = "";
open (IF, "<$if_name" ) || die  "Cno $if_name: $!.\n";
while ( <IF> ) {
    if ( /\>/ ) {
	if ( $dna_str ) {
	    process_seq ();
	}
	$dna_str = "";
	/\>\s*(.+)[\s\n]/;
	$seqname = $1;;
	next;
    }
    chomp;
    $aux_str = $_;
    $aux_str =~ s/\s//g;
    $aux_str =~ s/\d//g;
    $dna_str .= $aux_str;
  
}
process_seq ();
close IF;


sub process_seq () {
    @dna_seq = split '', $dna_str;


    $ctr=0;
    print ">$seqname\_$frameshift\n";
    for ($i=$frameshift; $i < $#dna_seq; $i +=3) {
	$ctr++;
	$codon = uc  join ('', @dna_seq[$i..$i+2]);
	if ( $codon =~ /[^ACTG]/ ) { # the codon matches something which is not ACTG
	    $trsl = "X";
	    #die "$if_name: Error in dna seq pos $i, protein seq pos $ctr: codon $codon.\n" ;
	} else {
	    $trsl =  $translation{ $codon}; 
	  
	}
	if ( $fancy ) {
	    printf " %4d   %3s  %1s \n", $ctr, lc $codon, $trsl;

	} else {
	    print  $trsl; 
	    if ( ! ($ctr %50 ) ) {
		print "\n";
	    }
	}
	
    }
    print "\n";
}






sub initialize_genetic_code () {
# the tables come from http://www3.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c

    my $table_no = $_[0];

    if ( $table_no == 1 ) {
       #1. The Standard Code (transl_table=1)
       #By default all transl_table in GenBank flatfiles are equal to id 1, and this is not shown. 
       #When transl_table is not equal to id 1, it is shown as a qualifier on the CDS feature.

	$AAs    = "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
	$Starts = "---M---------------M---------------M----------------------------";
	$Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
	$Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
	$Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

    } elsif ( $table_no == 2 ) {
#--
#2. The Vertebrate Mitochondrial Code (transl_table=2)

    $AAs  = "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG";
  $Starts = "--------------------------------MMMM---------------M------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  3 ) {
#3. The Yeast Mitochondrial Code (transl_table=3)

    $AAs  = "FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "----------------------------------MM----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  4 ) {
#4. The Mold, Protozoan, and Coelenterate Mitochondrial Code and the Mycoplasma/Spiroplasma Code (transl_table=4)

    $AAs  = "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "--MM---------------M------------MMMM---------------M------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==   5) {
#5. The Invertebrate Mitochondrial Code (transl_table=5)

    $AAs  = "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG";
  $Starts = "---M----------------------------MMMM---------------M------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  6 ) {
#6. The Ciliate, Dasycladacean and Hexamita Nuclear Code (transl_table=6)

    $AAs  = "FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==   9) {
#9. The Echinoderm and Flatworm Mitochondrial Code (transl_table=9)

    $AAs  = "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M---------------M------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  10 ) {
#10. The Euplotid Nuclear Code (transl_table=10)

    $AAs  = "FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no == 11 ) {
#11. The Bacterial and Plant Plastid Code (transl_table=11)

    $AAs  = "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "---M---------------M------------MMMM---------------M------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  12 ) {
#12. The Alternative Yeast Nuclear Code (transl_table=12)
#Systematic Range:
#Endomycetales (yeasts): Candida albicans, Candida cylindracea, Candida melibiosica, 
#Candida parapsilosis, and Candida rugosa (Ohama et al., 1993).
#Comment:
#   However, other yeast, including Saccharomyces cerevisiae, Candida azyma, Candida diversa, 
# Candida magnoliae, Candida rugopelliculosa, Yarrowia lipolytica, and Zygoascus hellenicus, 
# definitely use the standard (nuclear) code (Ohama et al., 1993). 
    $AAs  = "FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "-------------------M---------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  13) {
#13. The Ascidian Mitochondrial Code (transl_table=13)

    $AAs  = "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  14 ) {
#14. The Alternative Flatworm Mitochondrial Code (transl_table=14)

    $AAs  = "FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  15 ) {
#15. Blepharisma Nuclear Code (transl_table=15)

    $AAs  = "FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no == 16  ) {
#16. Chlorophycean Mitochondrial Code (transl_table=16)

    $AAs  = "FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no == 21  ) {
#21. Trematode Mitochondrial Code (transl_table=21)

    $AAs  = "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M---------------M------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no ==  22 ) {
#22. Scenedesmus obliquus mitochondrial Code (transl_table=22)

    $AAs  = "FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "-----------------------------------M----------------------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";

} elsif ( $table_no == 23  ) {
#23. Thraustochytrium Mitochondrial Code (transl_table=23)

    $AAs  = "FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG";
  $Starts = "--------------------------------M--M---------------M------------";
  $Base1  = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
  $Base2  = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
  $Base3  = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";
} else {
    die "Error: table number $table_no not defined.\n";
}


}
