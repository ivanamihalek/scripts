#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# "ce" is a  structural alignment program by Shnyidalov et co
# it works better with the original pdb than with the one with extracted chains
# it doesnt ouput the pdb, ony affine tf
# the affine tfm transforms name 2 into name 1

$seq[0]= "";
$seq[1]= "";

open (AFF, ">affine.tmp") ||
     die "Cno affine: $!.\n";

while ( <> ) {
    if ( /^Chain (\d)\:/ ) {
	$chainno = $1;
	if ( /Size/ ) {
	    /Chain \d\:\s(.+?)\.pdb\:\s*(\w)/;
	    $name[$chainno-1] = $1;
	    $chain = "";
	    ( defined $2) && ( $chain = $2);
	    
	    #$name[$chainno-1] = (lc $name[$chainno-1]).$chain;
	    print $name[$chainno-1], "\n";
	} else {
	    @aux = split;
	    $seq[$chainno-1] .= $aux[3];
	}
    } elsif ( /\((.+?)\).+\((.+?)\).+\((.+?)\).+\((.+?)\)/ ) {
	print  AFF " $1  $2   $3  $4\n";
    }
}

close AFF;

#####################################################
# put alignemnt in the msf format

$msfname = $name[0]."_".$name[1].".msf";

open (MSF, ">$msfname") ||
     die "Cno $msfname: $!.\n";


$seqlen = length $seq[0];
print MSF "PileUp\n\n";
print  MSF "            GapWeight: 30\n";
print  MSF "            GapLengthWeight: 1\n\n\n";
printf MSF  ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
for $i ( 0 ..1) {
    printf MSF  (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", "ce_".$name[$i], $seqlen);
}
printf MSF  "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    for $i ( 0 ..1) {
	printf  MSF "%-30s", "ce_".$name[$i];
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf  MSF ("%-10s ",   substr ($seq[$i], $j+$k*10 ));
		last;
	    } else {
		printf  MSF ("%-10s ",   substr ($seq[$i], $j+$k*10, 10));
	    }
	}
	printf  MSF "\n";
    } 
    printf MSF  "\n";
}
close MSF;

##################################################
# turns  ce chops chain terminals and inserts pieces
# for which the structure is not known - do profile alignment
# with cw to fix it
`clustalw -output=gcg -gapopen= 0.0 -gapext= 0.0 -profile1= $msfname -profile2= $name[0].seq `;
`clustalw -output=gcg -gapopen= 0.0  -gapext= 0.0 -profile1= $msfname -profile2= $name[1].seq `;


##################################################
`pdb_affine_tfm.pl $name[1]  affine.tmp`;

##################################################
# if the two chainnames are the same, change one
open (PDB, "< $name[0].pdb") ||
     die "Cno $name[0].pdb: $!.\n";
$line = <PDB>;
$chainname1 = substr ($line, 21, 1);
close PDB;

open (PDB, "< $name[1].rot.pdb") ||
     die "Cno $name[1].rot.pdb: $!.\n";
$line = <PDB>;
$chainname2 = substr ($line, 21, 1);
close PDB;

if ( $chainname1 =~ $chainname2 ) {
    if ( $chainname2 =~ /z/i ) {
	$chainname2  = "A";
    } else {
	$chainname2 =  chr (ord ($chainname2) + 1 );
    }
    `pdb_chain_rename.pl $name[1].rot $chainname2`;
}


##################################################
`cat $name[0].pdb $name[1].rot.pdb > tmp.pdb`;

format RS = 
load tmp.pdb
restrict protein
wireframe off
backbone 150
select :@<
        $chainname1
color red
select :@<
        $chainname2
color blue
.

open (RS, ">tmp.rs") ||
    die "Cno tmp.rs: $!.\n";
write RS;
close RS;

`rasmol -script tmp.rs`;

