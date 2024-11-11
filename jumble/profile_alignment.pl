#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# <struct msf> is an msf file obtained by structurally aligning
#   <pdb_name_1>  and  <pdb_name_2> 

defined ( $ARGV[4]) ||
    die "Usage: profile_alignment.pl   <pdb_name_1> <ranks_1>   <pdb_name_2>  <ranks_2> <struct_msf>.\n";

$query1 =  $ARGV[0];
$ranks1 =  $ARGV[1];
$query2 =  $ARGV[2];
$ranks2 =  $ARGV[3];

$structmsf = $ARGV[4];

##################################################################
#  read in the three msfs

open ( RNKS, "<$ranks1" ) ||
    die "Cno: $ranks1  $!\n";
@chain1=();
@pdbid1 = ();
@epi1 = ();
$epitope = 0;

while ( <RNKS>) {
    next if ( ! (/\S/) );
    if ( (/^%/) ) {
	if ( /epitope/ ) {
	    $epitope = 1;
	}
	next;
    }
    chomp;
    @aux = split;
    $residue = $aux[2];
    next if ( $residue =~ '\.');

    push @chain1, $residue;

    $rho =  $aux[$#aux-1];
    push @rho1, $rho;

    push @pdbid1, $aux[1];

    if ( $epitope ) {
	push @epi1, $aux[$#aux-1];
    }
}
close RNKS;



open ( RNKS, "<$ranks2" ) ||
    die "Cno: $ranks2  $!\n";
@chain2=();
@pdbid2 = ();
@epi2 = ();
$epitope = 0;
while ( <RNKS>) {
    next if ( ! (/\S/) );
    if ( (/^%/) ) {
	if ( /epitope/ ) {
	    $epitope = 1;
	}
	next;
    }
    chomp;
    @aux = split;
    $residue = $aux[2];
    next if ( $residue =~ '\.');

    push @chain2, $residue;

    $rho =  $aux[$#aux-1];
    push @rho2, $rho;

    push @pdbid2, $aux[1];

    if ( $epitope ) {
	push @epi2, $aux[$#aux-1];
    }
}
close RNKS;

open ( MSF, "<$structmsf" ) ||
    die "Cno: $structmsf  $!\n";
while ( <MSF>) {
    last if ( /\/\// );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $structseq{$seq_name} ){
	$structseq{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$structseq{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}
close MSF;




if ( ! defined  $structseq{$query1} ) {
    die  "$query1 not found in $structmsf\n";
} 
if ( ! defined $structseq{"ce_".$query1} ) {
    die  "ce_$query1 not found in $structmsf\n";
}

if ( ! defined  $structseq{$query2} ) {
    die  "$query2 not found in $structmsf\n";
} 
if ( ! defined $structseq{"ce_".$query2} ) {
    die  "ce_$query2 not found in $structmsf\n";
}


@array1 = split '', $structseq{$query1};
@array2 = split '', $structseq{$query2};

=pod
# rescale rho arrays 
$max_rho = -1;
foreach $rho ( @rho1 ) {
    if ($rho > $max_rho) {
	$max_rho = $rho;
    }
}

for $i  ( 0 .. $#rho1 ) {
    $rho1[$i] = ($max_rho + 1 - $rho1[$i] )/$max_rho;
}

$max_rho = -2;
foreach $rho ( @rho2 ) {
    if ($rho > $max_rho) {
	$max_rho = $rho;
    }
}
for $i  ( 0 .. $#rho2 ) {
    $rho2[$i] = ($max_rho + 1 - $rho2[$i] )/$max_rho;
}
=cut



$ctr1 = -1;
$ctr2 = -1;

for $i ( 0 .. $#array1 ) {
    $both_ok = 0;
    if ( $array1[$i] =~ '\.' || $array1[$i] =~ '\-' ) {
    } else {
	$ctr1++;
	$both_ok ++;
    }
    if ( $array2[$i] =~ '\.' || $array2[$i] =~ '\-' ) {
    } else {
 	$ctr2++;
	$both_ok ++;
    }
   
    #if ( $both_ok == 2 && $epi1[$ctr1] && $epi2[$ctr2]) {
    if ( $both_ok == 2 ) {
    #if (  $array1[$i] =~  $array2[$i] &&   $array2[$i] !~ '\.') {
	printf "%3s ",  $array1[$i];
	printf "%3s ",  $chain1[$ctr1];
	printf "%5s ",  $pdbid1[$ctr1];
	printf " %8.3f ", $rho1[$ctr1];
	if ( $rho1[$ctr1] <= 0.15 ) {
	    printf "%3d ", 1;
	} else {
	    printf "%3d ", 0;
	}


	printf "  %3s ",  $array2[$i];

	printf "%3s ",  $chain2[$ctr2];
	printf "%5s ",  $pdbid2[$ctr2];
	printf " %8.3f ", $rho2[$ctr2];
	if ( $rho2[$ctr2] <= 0.15 ) {
	    printf "%3d ", 1;
	} else {
	    printf "%3d ", 0;
	}
	print "\n";
    }
}
