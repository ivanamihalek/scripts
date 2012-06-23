#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# "ce" is a  structural alignment program by Shnyidalov et co
# it works better with the original pdb than with the one with extracted chains
# it doesnt ouput the pdb, ony affine tf
# the affine tfm transforms name 2 into name 1

# no matter where ce got the original pdb from, the chain pdb files should be
# in the working directory (or at least the links should)

$HOME = `echo \$HOME`; chomp $HOME;

$seq[0]= "";
$seq[1]= "";

open (AFF, ">affine.tmp") ||
     die "Cno affine: $!.\n";

while ( <> ) {
    if ( /^Chain (\d)\:/ ) {
	$chainno = $1;
	if ( /Size/ ) {
	    /Chain \d\:\s(.+?)\.pdb\:(\w)/;
	    #print "***  $1   ***  $2 *** \n";
	    $fullpath[$chainno-1] = $1;
	    $chain = "";
	    ( defined $2 && $2 !~ "_" ) && ( $chain = $2);
	    
	    if ( $fullpath[$chainno-1] =~ /\// ) {
		@aux = split  '\/', $fullpath[$chainno-1];
		$name[$chainno-1] = pop @aux;
	    } else {
		$name[$chainno-1] = $fullpath[$chainno-1];
	    }
	    
	    $name[$chainno-1] = (lc $name[$chainno-1]).$chain;
	    print $name[$chainno-1], "\n";
	} else {
	    chomp;
	    $seq[$chainno-1] .= substr $_, 14;
	}
    } elsif ( /\((.+?)\).+\((.+?)\).+\((.+?)\).+\((.+?)\)/ ) {
	print  AFF " $1  $2   $3  $4\n";
    }
}

close AFF;
#12345678901234567890
#Chain 1:  225 EGWVLANALLIDLHFAQTNPDRKQKLILDLSDIRPYGAEIHGFGGTASGPMPLISMLLDVNEVLNNKAGG
#Chain 2:      ----------------------------------------------------------------------

#####################################################
# put the alignement in the msf format

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

=pod
##################################################
# turns  ce chops chain terminals and inserts pieces
# for which the structure is not known - do profile alignment
# with cw to fix it
if  ( -e "$name[0].seq" ) {
     ( -e "tmp.msf" ) && `rm tmp.msf`;
    `clustalw -output=gcg -gapopen= 0.0 -gapext= 0.0 -profile1= $msfname -profile2= $name[0].seq -outfile= tmp.msf `;
    if ( -e "tmp.msf" ) {
	if  ( -e "$name[1].seq" ) {
	    ( -e "tmp2.msf" ) && `rm tmp2.msf`;
	    `clustalw -output=gcg -gapopen= 0.0 -gapext= 0.0 -profile1= tmp.msf -profile2= $name[1].seq -outfile= tmp2.msf `;
	    ( -e "tmp2.msf" ) && `grep -v ce\_ tmp2.msf > $name[0]\_$name[1].full_length.msf`;
	} else { 
	    warn "Could not find $name[1].seq.\n";
	}
	`rm tmp.msf`;
    }
} else {
    warn "Could not find $name[0].seq.\n";
}
=cut

##################################################
`$HOME/perlscr/pdb_manip/pdb_affine_tfm.pl $name[1].pdb  affine.tmp > $name[1].rot.pdb`;

##################################################
# if the two chainnames are the same, change one
open (PDB, "< $name[0].pdb") ||
     die "Cno $name[0].pdb: $!.\n";
while ( <PDB> ) {
    last if (  /^ATOM/) ;
}
$chainname1 = substr ($_, 21, 1);
$chainname1 =~ s/\s//;
close PDB;

$rotated_pdb =  "$name[1].rot.pdb";
open (PDB, "< $rotated_pdb") ||
     die "Cno $rotated_pdb: $!.\n";
while ( <PDB> ) {
    last if ( /^ATOM/) ;
}
$chainname2 = substr ($_, 21, 1);
$chainname2 =~ s/\s//;
close PDB;

if ( $chainname1 && $chainname2 ) {

    if ( $chainname1 ne  $chainname2 ) {

	`cp $name[0].pdb tmp1.pdb`;
	`cp $name[1].rot.pdb tmp2.pdb`;
	
    } else  {
	if ( $chainname2 =~ /z/i ) {
	    $chainname2  = "A";
	} else {
	    #$chainname2 =  chr (ord ($chainname2) + 1 );
	    $chainname2 =  "Z";
	}
	`$HOME/perlscr/pdb_manip/pdb_chain_rename.pl $name[1].rot.pdb  $chainname2 > renamed`;
	`mv renamed  $name[1].rot.pdb`;
	`cp $name[0].pdb tmp1.pdb`;
	`cp $name[1].rot.pdb tmp1.pdb`;
    }
} else  {
    $chainname1  = "A";
    $chainname2  = "B";
   
    `$HOME/perlscr/pdb_manip/pdb_chain_rename.pl $name[0].pdb  $chainname1 > tmp1.pdb`;
    `$HOME/perlscr/pdb_manip/pdb_chain_rename.pl $name[1].rot.pdb  $chainname2 > tmp2.pdb`;
   
} 


##################################################
$concat_pdb = "$name[0].$name[1].pdb";
$cmdline = "cat    tmp1.pdb  tmp2.pdb  >  $concat_pdb";
#print $cmdline, "\n";
`$cmdline`;

format RS = 
load   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        $concat_pdb
restrict protein
wireframe off
backbone 150
select :@<
        $chainname1
color blue
select :@<
        $chainname2
color red
select ligand
spacefill
color green
.



$rs =  "$name[0].$name[1].rs";
open (RS, ">$rs") ||
    die "Cno $rs: $!.\n";
write RS;
close RS;

#`rasmol -script $rs`;

