#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0] ) ||
    die "Usage: partial_charges.pl <pdb_name>.\n";
$pdb = $ARGV[0];

open ( IF, "<$pdb.pdb" ) ||
    die "Cno $pdb.pdb:$!.\n";
open ( OF, ">$pdb.pdbq" ) ||
    die "Cno $pdb.pdbq:$!.\n";


%charge = ();

set_charge();

while ( <IF> ) {

    if ( ! /^ATOM/ ) {
	print OF ;
	next;
    }
    $aa = substr ($_, 17, 3);
    if ( $aa =~ "HEM" || $aa =~ "HOH") {
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
    if ( defined $charge{$key} ) {
	#printf "      %7.3f\n",     $charge{$key};
    } else {
	print " Warning: $key entry not defined.\n";
    }

    # looks like I have to format it seriously
    $record = substr $_, 0, 6;  $record =~ s/\s//g;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $name = substr $_,  12, 4 ;  $name =~ s/\s//g;
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
    $chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;


    if ( length($name) ==4 &&  $name =~ /(..)(\d)(\d)/) {
	$name = $2.$1.$3;; # change name to conform to retarded adt
                         
    }
    if ( (length  $name) == 4 ) {# whoever wrote adt is completely retarded, I swear
	printf OF "%-6s%5d %-4s%1s%-3s %1s%4d%1s   %8.3f%8.3f%8.3f", 
	$record,   $serial,  $name,   $alt_loc,   $res_name,
	$chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;
    } else {
	printf OF "%-6s%5d  %-3s%1s%-3s %1s%4d%1s   %8.3f%8.3f%8.3f", 
	$record,   $serial,  $name,   $alt_loc,   $res_name,
	$chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;
    }

    if (  length $_ >= 60 ) {
	$occupancy = substr $_, 54, 6;
	if ( $occupancy =~ /\S/)  {
	    printf OF "%6.2f",$occupancy
	} else {
	    printf OF "%6.2f", 1.0;
	}
    } else {
	printf OF "%6.2f", 1.0;
    }
    if (  length $_ >= 66 ) {
	$temp_factor = substr $_, 60, 6;
	if ( $temp_factor =~ /\S/)  {
	    printf OF "%6.2f",$temp_factor;
	} else {
	    printf OF "%6.2f", 0.0;
	}
    } else {
	printf OF "%6.2f", 0.0;
    }

    printf OF "%10.3f\n", $charge{$key};
    
}


close IF;
close OF;





sub set_charge {
    %charge = (
	       "ALAN", -0.520,
	       "ALAH",  0.248,
	       "ALACA", 0.215,
	       "ALACB", 0.031,
	       "ALAC",  0.526, 
	       "ALAO", -0.50,

	       "ARGN",     -0.520,
	       "ARGH",      0.248,
	       "ARGCA",      0.237,
	       "ARGCB",      0.049,
	       "ARGCG",      0.058,
	       "ARGCD",      0.111,
	       "ARGNE",     -0.493,
	       "ARGHE",      0.294,
	       "ARGCZ",      0.813,
	       "ARGNH1",     -0.634,
	       "ARGHH11",      0.361, "ARG1HH1",  0.361,
	       "ARGHH12",      0.361, "ARG1HH2",  0.361,
	       "ARGNH2",     -0.634,
	       "ARGHH21",      0.361, "ARG2HH1",  0.361,
	       "ARGHH22",      0.361, "ARG2HH2",  0.361,
	       "ARGC",      0.526,
	       "ARGO",     -0.500,

	   "ASNN",     -0.520,
	   "ASNH",      0.248,
	   "ASNCA",      0.217,
	   "ASNCB",      0.003,
	   "ASNCG",      0.675,
	   "ASNOD1",     -0.470,
	   "ASNND2",     -0.867,
	   "ASNHD21",      0.344, "ASN1HD2", 0.344,
	   "ASNHD22",      0.344,  "ASN2HD2", 0.344,
	   "ASNC",      0.526,
	   "ASNO",     -0.500,

	   "ASPN",     -0.520, 
	   "ASPH",      0.248,
	   "ASPCA",      0.246,
	   "ASPCB",     -0.208,
	   "ASPCG",      0.620,
	   "ASPOD1",     -0.706,
	   "ASPOD2",     -0.706,
	   "ASPC",      0.526,
	   "ASPO",     -0.500,
 
	   "CYSN", -0.520,
	   "CYSH",  0.248,
	   "CYSCA", 0.146,
	   "CYSCB", 0.100,
	   "CYSSG",-0.135,
	   "CYSHG", 0.135,
	   "CYSC",  0.526,
	   "CYSO", -0.500,

 	  "GLNN",     -0.520,
 	  "GLNH",      0.248,
 	  "GLNCA",      0.210,
 	  "GLNCB",      0.053,
 	  "GLNCG",     -0.043,
 	  "GLNCD",      0.675,
	   "GLNOE1",     -0.470,
	   "GLNNE2",     -0.867,
 	  "GLNHE21",      0.344, "GLN1HE2",      0.344,
 	  "GLNHE22",      0.344, "GLN2HE2",      0.344,
 	  "GLNC",      0.526,
 	  "GLNO",     -0.500,

	   "GLUN",  -0.520 ,
	   "GLUH",   0.248,
	   "GLUCA",  0.246 ,
	   "GLUCB",  0.000 ,
	   "GLUCG",   -0.208 ,
	   "GLUCD",  0.620 ,
	   "GLUOE1",  -0.706 ,
	   "GLUOE2",  -0.706 ,
	   "GLUC",   0.526,
	   "GLUO",  -0.500 ,

	   "GLYN",  -0.520,
	   "GLYH", 0.248,
	   "GLYCA", 0.246,
	   "GLYC",  0.526, 
	   "GLYO",-0.50,

	   "HISN",  -0.520,
	   "HISH",  0.248,
	   "HISCA", 0.219,
	   "HISCB", 0.060,
	   "HISCG", 0.089,
	   "HISCD2", 0.145,
	   "HISND1", -0.444,
	   "HISHD1",  0.320,
	   "HISCE1", 0.384,
	   "HISNE2", -0.527,
	   "HISHE2", 0.000,
	   "HISC", 0.526,
	   "HISO", -0.500,
	   
	   "ILEN",   -0.520,
	   "ILEH",  0.248,
	   "ILECA", 0.199,
	   "ILECB", 0.030,
	   "ILECG2", 0.001,
	   "ILECG1", 0.017,
	   "ILECD1", -0.001,
	   "ILECD", -0.001,
	   "ILEC",  0.526,
	   "ILEO", -0.500,

	   "LEUN", -0.520,
	   "LEUH" , 0.248,
	   "LEUCA", 0.204,
	   "LEUCB", 0.016, 
	   "LEUCG", 0.054, 
	   "LEUCD1", 0.014, 
	   "LEUCD2", 0.014,
	   "LEUC", 0.526, 
	   "LEUO", -0.50,

	   "LYSN", -0.520 ,
	   "LYSH",  0.248 ,
	   "LYSCA",  0.227 ,
	   "LYSCB",  0.039 ,
	   "LYSCG",  0.053 ,
	   "LYSCD",  0.048 ,
	   "LYSCE",   0.218,
	   "LYSNZ",   -0.272,
	   "LYSHZ1",  0.311 ,
	   "LYSHZ2",  0.311 ,
	   "LYSHZ3", 0.311  ,  
	   "LYSC",  0.526 ,
	   "LYSO",  -0.500 ,
	   "LYSO1",  -0.500 ,
	   "LYSO2",  -0.500 ,

	   "METN",     -0.520,
	   "METH",      0.248,
	   "METCA",      0.137,
	   "METCB",      0.037,
	   "METCG",      0.090,
	   "METSD",     -0.025,
	   "METCE",      0.007,
	   "METC",      0.526,
	   "METO",     -0.500,

	   "PHEN",     -0.520,
	   "PHEH",     0.248,
	   "PHECA",      0.214,
	   "PHECB",     0.038,
	   "PHECG",     0.011,
	   "PHECD1",      -0.011,
	   "PHECD2",      -0.011,
	   "PHECE1",      0.004,
	   "PHECE2",      0.004,
	   "PHECZ",      -0.003,
	   "PHEC",      0.526,
	   "PHEO",      -0.500, 

	   "PRON",     -0.257,
	   "PROCD",      0.084,
	   "PROCA",      0.112,
	   "PROCB",     -0.001,
	   "PROCG",      0.036,
	   "PROC",      0.526,
	   "PROO",     -0.500,

	   
	       "SERN",     -0.520,
	       "SERH",      0.248,
	       "SERCA",      0.292,
	       "SERCB",      0.194,
	       "SEROG",     -0.550,
	       "SERHG",      0.310,
	       "SERC",      0.526,
	       "SERO",     -0.500,

	       "THRN",     -0.520,
	       "THRH",      0.248,
	       "THRCA",      0.268,
	       "THRCB",      0.211,
	       "THROG1",     -0.550,
	       "THRHG1",      0.310,
	       "THRCG2",      0.007,
	       "THRC",      0.526,
	       "THRO",     -0.500,

	   "TRPN",     -0.520,
	   "TRPH",      0.248,
	   "TRPCA",      0.248,
	   "TRPCB",      0.020,
	   "TRPCG",      0.046,
	   "TRPCD2",     -0.275,
	   "TRPCE2",      0.000,
	   "TRPCE3",      0.145,
	   "TRPCD1",      0.117,
	   "TRPNE1",     -0.330,
	   "TRPHE1",      0.294,
	   "TRPCZ2",      0.029,
	   "TRPCZ3",     -0.082,
	   "TRPCH2",      0.034,
	   "TRPC",      0.526,
	   "TRPO",     -0.500,

	   "TYRN",     -0.520,
	   "TYRH",      0.248,
	   "TYRCA",      0.245,
	   "TYRCB",      0.022,
	   "TYRCG",     -0.001,
	   "TYRCD1",     -0.035,
	   "TYRCE1",      0.100,
	   "TYRCD2",     -0.035,
	   "TYRCE2",      0.100,
	   "TYRCZ",     -0.121,
	   "TYROH",     -0.368,
	   "TYRHH",      0.339,
	   "TYRC",      0.526,
	   "TYRO",     -0.500,

	   "VALN",     -0.520,
	   "VALH",      0.248,  
	   "VALCA",      0.201,
	   "VALCB",      0.033,
	   "VALCG1",      0.006,
	   "VALCG2",      0.006,
	   "VALC",      0.526,
	   "VALO",     -0.500
	   );

}
