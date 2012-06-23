#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0] ) ||
    die "Usage: solvent.pl <pdb_name>.\n";
$pdb = $ARGV[0];

open ( IF, "<$pdb.pdbq" ) ||
    die "Cno $pdb.pdbq:$!.\n";
open ( OF, ">$pdb.pdbqs" ) ||
    die "Cno $pdb.pdbqs:$!.\n";


%solvent = ();

set_solvent();

while ( <IF> ) {

    if ( ! /^ATOM/ ) {
	print OF ;
	next;
    }
    chomp;

    $atom_name = substr $_, 12, 4;
    $atom_name =~ s/\s//g;
    if ( $atom_name =~ "HN" && length($atom_name) ==3 ) {
	if (  $atom_name =~ "1" ) {
	    $atom_name = "H"; # synonym
	} else {
	    next;
	}
    }
    if ( $atom_name =~ "HN" && length($atom_name) ==2 ) {
	$atom_name = "H"; # synonym
    }
    if ( $atom_name =~ "OXT" && length($atom_name) ==3 ) {
	$atom_name = "O"; # this is terminal oxigan - what would be the
                          # correct way to handle it?
    }
    $aa_type = substr $_, 17, 3;
    $aa_type =~ s/\s//g;
    #print " $aa_type    $atom_name"; 
    $key = uc $aa_type.$atom_name;
    if ( defined $solvent{$key} ) {
	#printf "      %7.3f\n",     $solvent{$key};
    } else {
	$key = substr $key, 3;
	if ( !defined $solvent{$key} ) {
	    print " Warning: $key entry not defined.\n";
	}
    }
    if ( defined  $solvent{$key} ) {
	$solvpar =  $solvent{$key};
    } else {
	$solvpar =   " 0.00    0.00";
    }
    printf OF "%-s%16s\n", $_,  $solvpar;
    
}


close IF;
close OF;





sub set_solvent {
    %solvent = (
"C",   " 9.82    4.00",
"O",   " 8.17  -17.40",
"N",   " 9.00  -17.40",
"CA",   " 9.40    4.00",
"ALACB",   "16.15    4.00",
"ARGCB",   "12.77    4.00",
"ARGCG",   "12.77    4.00",
"ARGCD",   "12.77    4.00",
"ARGNE",   " 9.00  -24.67",
"ARGCZ",   " 6.95    4.00",
"ARGNH1",   " 9.00  -24.67",
"ARGNH2",   " 9.00  -24.67",
"ASNCB",   "12.77    4.00",
"ASNCG",   " 9.82    4.00",
"ASNOD1",   " 8.17  -17.40",
"ASNND2",   "13.25  -17.40",
"ASPCB",   "12.77    4.00",
"ASPCG",   " 9.82    4.00",
"ASPOD1",   " 8.17  -18.95",
"ASPOD2",   " 8.17  -18.95",
"CYSCB",   "12.77    4.00",
"CYSSG",   "19.93   -6.40",
"GLUCB",   "12.77    4.00",
"GLUCG",   "12.77    4.00",
"GLUCD",   " 9.82    4.00",
"GLUOE1",   " 8.17  -18.95",
"GLUOE2",   " 8.17  -18.95",
"PHECB",   "12.77    4.00",
"PHECG",   " 7.26    0.60",
"PHECD1",   "10.80    0.60",
"PHECD2",   "10.80    0.60",
"PHECE1",   "10.80    0.60",
"PHECE2",   "10.80    0.60",
"PHECZ",   "10.80    0.60",
"PROCB",   "12.77    4.00",
"PROCG",   "12.77    4.00",
"PROCD",   "12.77    4.00",
"GLNCB",   "12.77    4.00",
"GLNCG",   "12.77    4.00",
"GLNCD",   " 9.82    4.00",
"GLNOE1",   " 8.17  -17.40",
"GLNNE2",   "13.25  -17.40",
"HISCB",   "12.77    4.00",
"HISCG",   " 7.26    0.60",
"HISND1",   " 9.25  -17.40",
"HISCD2",   "10.80    0.60",
"HISCE1",   "10.80    0.60",
"HISNE2",   " 9.25  -17.40",
"ILECB",   " 9.40    4.00",
"ILECG1",   "12.77    4.00",
"ILECG2",   "16.15    4.00",
"ILECD1",   "16.15    4.00",
"LEUCB",   "12.77    4.00",
"LEUCG",   " 9.40    4.00",
"LEUCD1",   "16.15    4.00",
"LEUCD2",   "16.15    4.00",
"LYSCB",   "12.77    4.00",
"LYSCG",   "12.77    4.00",
"LYSCD",   "12.77    4.00",
"LYSCE",   "12.77    4.00",
"LYSNZ",   "13.25  -39.20",
"METCB",   "12.77    4.00",
"METCG",   "12.77    4.00",
"METSD",   "16.39   -6.40",
"METCE",   "16.15    4.00",
"TRPCB",   "12.77    4.00",
"TRPCG",   " 7.26    0.60",
"TRPCD1",   "10.80    0.60",
"TRPCD2",   " 6.80    0.60",
"TRPNE1",   " 9.00  -17.40",
"TRPCE2",   " 6.80    0.60",
"TRPCE3",   "10.80    0.60",
"TRPCZ2",   "10.80    0.60",
"TRPCZ3",   "10.80    0.60",
"TRPCH2",   "10.80    0.60",
"SERCB",   "12.77    4.00",
"SEROG",   "11.04  -17.40",
"THRCB",   " 9.40    4.00",
"THROG1",   "11.04  -17.40",
"THRCG2",   "16.15    4.00",
"TYRCB",   "12.77    4.00",
"TYRCG",   " 7.26    0.60",
"TYRCD1",   "10.80    0.60",
"TYRCD2",   "10.80    0.60",
"TYRCE1",   "10.80    0.60",
"TYRCE2",   "10.80    0.60",
"TYRCZ",   " 7.26    0.60",
"TYROH",   "10.94  -17.40",
"VALCB",   " 9.40    4.00",
"VALCG1",   "16.15    4.00",
"VALCG2",   "16.15    4.00",
"HEMFE",   " 1.70  -39.20",
"HEMCHA",   "10.80    0.60",
"HEMCHB",   "10.80    0.60",
"HEMCHC",   "10.80    0.60",
"HEMCHD",   "10.80    0.60",
"HEMC1A",   "10.80    0.60",
"HEMC2A",   "10.80    0.60",
"HEMC3A",   "10.80    0.60",
"HEMC4A",   "10.80    0.60",
"HEMCMA",   "16.15    4.00",
"HEMNB",   " 9.25  -17.40",
"HEMC1B",   "10.80    0.60",
"HEMC4B",   "10.80    0.60",
"HEMNC",   " 9.25  -17.40",
"HEMC1C",   "10.80    0.60",
"HEMC2C",   "10.80    0.60",
"HEMC3C",   "10.80    0.60",
"HEMC4C",   "10.80    0.60",
"HEMCMC",   "16.15    4.00",
"HEMND",   " 9.25  -17.40",
"HEMC1D",   "10.80    0.60",
"HEMC4D",   "10.80    0.60",
"HEMNA",   " 9.25  -17.40",
"HEMCAA",   "12.77    4.00",
"HEMCBA",   "12.77    4.00",
"HEMCGA",   " 9.82    4.00",
"HEMO1A",   " 8.17  -18.95",
"HEMO2A",   " 8.17  -18.95",
"HEMC1A",   "10.80    0.60",
"HEMC2B",   "10.80    0.60",
"HEMCMB",   "16.15    4.00",
"HEMC3B",   "10.80    0.60",
"HEMCAB",   "12.77    4.00",
"HEMCBB",   "16.15    4.00",
"HEMCAC",   "12.77    4.00",
"HEMCBC",   "16.15    4.00",
"HEMC2D",   "10.80    0.60",
"HEMCMD",   "16.15    4.00",
"HEMC3D",   "10.80    0.60",
"HEMCAD",   "12.77    4.00",
"HEMCBD",   "12.77    4.00",
"HEMCGD",   " 9.82    4.00",
"HEMO1D",   " 8.17  -18.95",
"HEMO2D",   " 8.17  -18.95",
"CXLC",   " 9.82    4.00",
"CXLO1",   " 8.17  -18.95",
"CXLO2",   " 8.17  -18.95",
"AMNN",   "13.25  -39.20",
"XXXXX",   "13.25  -39.20",
"---OXY",   " 8.17  -17.40",
"HEMAHA",   "10.80    0.60",
"HEMAHB",   "10.80    0.60",
"HEMAHC",   "10.80    0.60",
"HEMAHD",   "10.80    0.60",
"HEMA1A",   "10.80    0.60",
"HEMA2A",   "10.80    0.60",
"HEMA3A",   "10.80    0.60",
"HEMA4A",   "10.80    0.60",
"HEMAMA",   "16.15    4.00",
"HEMA1B",   "10.80    0.60",
"HEMA4B",   "10.80    0.60",
"HEMA1C",   "10.80    0.60",
"HEMA2C",   "10.80    0.60",
"HEMA3C",   "10.80    0.60",
"HEMA4C",   "10.80    0.60",
"HEMAMC",   "16.15    4.00",
"HEMA1D",   "10.80    0.60",
"HEMA4D",   "10.80    0.60",
"HEMAAA",   "12.77    4.00",
"HEMABA",   "12.77    4.00",
"HEMAGA",   " 9.82    4.00",
"HEMA1A",   "10.80    0.60",
"HEMA2B",   "10.80    0.60",
"HEMAMB",   "16.15    4.00",
"HEMA3B",   "10.80    0.60",
"HEMAAB",   "12.77    4.00",
"HEMABB",   "16.15    4.00",
"HEMAAC",   "12.77    4.00",
"HEMABC",   "16.15    4.00",
"HEMA2D",   "10.80    0.60",
"HEMAMD",   "16.15    4.00",
"HEMA3D",   "10.80    0.60",
"HEMAAD",   "12.77    4.00",
"HEMABD",   "12.77    4.00",
"HEMAGD",   " 9.82    4.00",
	   );

}
