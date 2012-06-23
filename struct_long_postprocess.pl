#!/usr/bin/perl -w

use strict;
sub matrix_from_ce ( @);


(@ARGV ) ||
    die "Usage: $0 <long_out_from_struct>\n";


my $pdbdir         = "/home/ivanam/databases/pdbfiles";
my $extract_chain  = "/home/ivanam/perlscr/pdb_manip/pdb_extract_chain.pl";
my $extract_region = "/home/ivanam/perlscr/extractions/extr_region_from_pdb.pl";
my $pom            = "/home/ivanam/downloads/ce_distr/pom";
my $ce             = "/home/ivanam/downloads/ce_distr/CE";
my $pdb_aff        =  "/home/ivanam/perlscr/pdb_manip/pdb_affine_tfm.pl";
my ($long_out_file) = @ARGV;
my ($target, $qry, $pml);

foreach $_ ($pdbdir, $extract_chain, $extract_region, $long_out_file,
    $pom, $ce, $pdb_aff) {
    (-e $_) || die "$_ not found\n";
}

my (%from, %to);
my ($piece, %piece_of_pdb); 
my ($name, $pdbname, $chain);
my ($reading, $cmd, $has_submap);
my ($ce_zscore, $rotated_pdb);

###########################################
# find both matching regions
$reading =  0;

%{$from{"sub"}}  = ();
%{$from{"main"}} = ();
%{$to  {"sub"}}  = ();
%{$to  {"main"}} = ();

$has_submap = 0;
open (STRUCT_OUT, "<$long_out_file") ||
    die "Cno $long_out_file: $!.\n";

while ( <STRUCT_OUT> ) {

    next if ( !/\S/);
    last if (/matches/);

    if (/\*\*\s+(\w+?)\s+(\w+?)\s+/) {  
	$target = $1;
	$qry    = $2;
	(/with submap/) && ($has_submap = 1);

    } elsif (/total/) {
	if ( $has_submap ) {
	    $reading = 0;
	} else {
	    last;
	}

    } else {

	if ( $reading ) {
	    next if ( /map/);
	    if ( /\s+([\-\d]+)\s*\-\s*([\-\d]+)\s+([\-\d]+)\s*\-\s*([\-\d]+)/) {
		(defined $from{$piece}{$target})    || ($from{$piece}{$target} = $1);
		(defined $from{$piece}{$qry}) || ($from{$piece}{$qry} = $3);
		$to{$piece}{$target}    = $2;
		$to{$piece}{$qry} = $4;
	    } else {
		die "$_ error parsing $long_out_file (note: header processing not implemented)\n";
	    }
	}

	if ( !$reading && /^map/  ) {
	    $reading = 1;
	    if ( /submatch/) {
		$piece = "sub";
	    } else {
		$piece = "main";
	    }
	}

    }
}
close STRUCT_OUT;

print "main match \n";
$piece = "main";
print "$qry  from: $from{$piece}{$qry}   to: $to{$piece}{$qry}  ".
    " |  $target  from: $from{$piece}{$target}  to: $to{$piece}{$target} \n";

if ( $has_submap) {
    print "submatch \n";
    $piece = "sub";
    print "$qry  from: $from{$piece}{$qry}   to: $to{$piece}{$qry}  ".
	" |  $target  from: $from{$piece}{$target}  to: $to{$piece}{$target} \n";
}


###################################################
# extract the  main matching piece from both pdbs
%piece_of_pdb = ();
$piece = "main";

foreach $name ($qry, $target) {
    
    $pdbname = substr $name, 0, 4;
    $chain   = substr $name, 4, 1;

    if ( ! -e "$name.pdb" ) {
	$cmd = "$extract_chain $pdbdir/$pdbname.pdb $chain > $name.pdb";
	(system $cmd ) && die "error running $cmd\n";
    }

    $piece_of_pdb{$name} = "$name.$from{$piece}{$name}"."_$to{$piece}{$name}.pdb";

    if ( ! -e $piece_of_pdb{$name} ) {
	$cmd    = "$extract_region $name.pdb  ";
	$cmd   .= " $from{$piece}{$name}  $to{$piece}{$name} > $piece_of_pdb{$name} ";
	(system $cmd ) && die "error running $cmd\n";
	print "$cmd\n";
    }
}

# needed for CE
(-e "pom") || `ln -s $pom .`;

########################################
# find the transformation which matches main piece in target
# onto main piece in query
$piece = "main";
	
$cmd = "$ce - $piece_of_pdb{$qry} - $piece_of_pdb{$target} - /tmp > $piece.ce_out";
(system $cmd ) && die "error running $cmd\n";

$ce_zscore = matrix_from_ce("$piece.ce_out", "$piece.matrix");
print "$piece CE z-score: $ce_zscore \n";

########################################
# rotate the whole target onto query
$rotated_pdb = "$target.rot.pdb";
if ( ! -e $rotated_pdb ) {
    if (  -e "$piece.matrix" && ! -z "$piece.matrix" ) {
	$cmd = "$pdb_aff  $target.pdb  $piece.matrix > $rotated_pdb  ";
	(system $cmd ) && die "error running $cmd\n";
    }
}

if ($has_submap) {

    ########################################
    # now extract the sub match from the query
    # and from the  *rotated*  target
    $piece = "sub";
    foreach $name ($qry, $target) {

	$pdbname =  substr $name, 0, 4;
	$chain = substr $name, 4, 1;

	(  -e "$name.pdb" ) ||  die "error running $name.pdb not found\n";
	
	if ( $name eq $target ) {
	    $piece_of_pdb{$name} = "$name.$from{$piece}{$name}"."_$to{$piece}{$name}.rot.pdb";
	} else {
	    $piece_of_pdb{$name} = "$name.$from{$piece}{$name}"."_$to{$piece}{$name}.pdb";
	    
	}

	if ( ! -e $piece_of_pdb{$name} ) {
	    if ( $name eq $target ) {
		$cmd    = "$extract_region $name.rot.pdb  ";
	    } else {
		$cmd    = "$extract_region $name.pdb  ";
	    }
	    $cmd   .= " $from{$piece}{$name}  $to{$piece}{$name} > $piece_of_pdb{$name} ";
	    (system $cmd ) && die "error running $cmd\n";
	}
    }
    ########################################
    # rotate the sub-match piece from qry
    # onto rotated target
	
    $cmd = "$ce - $piece_of_pdb{$target} - $piece_of_pdb{$qry} - /tmp > $piece.ce_out";
    (system $cmd ) && die "error running $cmd\n";

    $ce_zscore = matrix_from_ce("$piece.ce_out", "$piece.matrix");
    print "$piece CE z-score: $ce_zscore \n";

    $rotated_pdb = "$qry.sub.rot.pdb";
    if ( ! -e $rotated_pdb ) {
	if (  -e "$piece.matrix" && ! -z "$piece.matrix" ) {
	    $cmd = "$pdb_aff  $piece_of_pdb{$qry} $piece.matrix > $rotated_pdb  ";
	    (system $cmd ) && die "error running $cmd\n";
	}
    }
} # end submap case

###########################################
# make pymol script
$pml = "$target\_$qry.pml";
$pdbname = substr $qry, 0, 4;

(  -e "$pdbname.pdb" ) || `ln -s $pdbdir/$pdbname.pdb . `;

open ( PML, ">$pml") || die "Cno $pml: $!\n";
print PML "load $pdbname.pdb, qry\n";
print PML "load $target.rot.pdb, target\n";
print PML "cmd.as(\"cartoon\"   ,\"qry\") \n";
print PML "cmd.as(\"ribbon\"   ,\"target\") \n";
if ( $has_submap) {
    print PML "load $qry.sub.rot.pdb, qry_sub\n";
    print PML "cmd.as(\"cartoon\"   ,\"qry_sub\") \n";
print PML "cmd.color(32, \"qry_sub\") \n";
}
print PML "cmd.bg_color(\'white\')\n";
close PML;



#################################################
#################################################
sub matrix_from_ce ( @) {

    my ($ce_out, $matrix_file) = @_;
    my ( $max_z, $max_ctr, $ctr);
    my @zscore = ();
    my @matrix = ();

    open (CE,"<$ce_out") || die "Cno $ce_out: $!.\n";

    $max_z = -100;
    $max_ctr = -1;
    $ctr = 0; # there might be multiple solutions - spit out the best one
    while ( <CE> ) {
	if ( /^Alignment/ ) {
	    /Z\-Score = ([\d\.]+) /;
	    $zscore[$ctr] = $1;
	    if ($max_z < $zscore[$ctr] ) {
		$max_z = $zscore[$ctr];
		$max_ctr = $ctr;
	    }
	} elsif ( /\((.+?)\).+\((.+?)\).+\((.+?)\).+\((.+?)\)/ ) {
	    $matrix[$ctr] .=   " $1  $2   $3  $4\n";
	    ( /Z2/ ) && $ctr++; 
	}
    }

    close CE;

    open (MAT,">$matrix_file") || die "Cno $matrix_file: $!.\n";
    print MAT $matrix[$max_ctr];
    close MAT;

    return $max_z;

}

