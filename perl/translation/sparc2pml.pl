#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

$carb = "/home/ivanam/perlscr/pdb_manip/carbon_line.pl";

$reading = "";
@sse = ();
while ( <IF> ) {
    next if ( !/\S/ );
    next if  (/^number/);
    if ( /^name/ ){
	chomp;
	@aux = split;
	$pdbname = pop @aux;
	next;
    }
    if ( /^HELIX/ ) {
	@aux = split;
	$reading  = "H".$aux[1];
	@{$line{$reading }} = ();
	push @sse, $reading;
    } elsif ( /^STRAND/ ) {
 	@aux = split;
	$reading  = "S".$aux[1];
	@{$line{$reading }} = ();
	push @sse, $reading;

   } elsif ( /^red_rep_end/ ) {
	last;
   } else {
       chomp;
       push @{$line{$reading }}, $_;
   }
}

while ( <IF> ) {
    next if ( !/\S/ );
    next if (/^backbone/ );
    if ( /^bb_end/ ) {
	last;
    } elsif ( /^HELIX/ ) {
	@aux = split;
	$reading  = "H".$aux[1];
	@{$residues{$reading }} = ();
    } elsif ( /^STRAND/ ) {
 	@aux = split;
	$reading  = "S".$aux[1];
	@{$residues{$reading }} = ();

   } elsif ( /line/ ) {
       chomp;
       @aux = split;
       push @{$residues{$reading }}, "$aux[3]-$aux[4]";
   }
}
close IF;


#########################################################
#########################################################
#########################################################

$pymol_scr = "load $pdbname.pdb\n";
$pymol_scr .= "hide all\n";
$pymol_scr .= "show ribbon\n";
$pymol_scr .= "set sphere_scale=.2\n\n";
foreach $sse ( @sse) {

    $no_lines = @{$line{$sse}};

    open (TMP, ">tmp") || die "Cno tmp: $!.\n";

    foreach $i( 0 .. $no_lines-1  ) {
	$ln = $line{$sse}[$i];
	print TMP $ln."\n";
    }

    close TMP;

    $cmd = "$carb tmp > $sse\_carb.pdb";
    (system $cmd ) && die "Error running $cmd: $!.\n";

    $pymol_scr .= "load $sse\_carb.pdb\n";

    $residues = join " or resi ", @{$residues{$sse}};
    $pymol_scr .= "select $sse\_atoms, (resi $residues) ";
    if ( $sse =~ /S/ ) {
	$pymol_scr .= " and (name C or name  N) ";
    } else {
	$pymol_scr .= " and (name CA) ";
    }

    $pymol_scr .= "\n";
    $pymol_scr .= "show spheres, $sse\_atoms\n";
    $pymol_scr .= "color red, $sse\_atoms\n";
    $pymol_scr .= "\n";
}

$pymol_scr .= "\nzoom $pdbname\n\n";

open (PYM, ">$pdbname.pml") || die "Cno $pdbname.pml: $!.\n";
print PYM $pymol_scr;
close PYM;
