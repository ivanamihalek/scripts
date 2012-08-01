#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( @ARGV == 1  ) ||
    die "Usage: fit_to_first_frame.pl   <pdb_file>.\n";

($pdbfile)  = @ARGV;	


$cedir  = "/home/ivanam/downloads/ce_distr";
$extr   = "/home/ivanam/perlscr/extractions/matrix_from_ce.pl";
$rotate = "/home/ivanam/perlscr/pdb_manip/pdb_affine_tfm.pl";

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$reading = 0;
$outstr = "";
while ( <IF> ) {
    if ( /^MODEL\s+(\d+)/ ) {
       $model_no = $1;
       $reading  =  1;
       $outstr   = $_;
    } elsif ( $reading  &&  (/^ENDMDL/ || /^TER/)  ) {
	$outstr .= "ENDMDL\n";
	if (! $model_no ) {
	    $file = "frame0.pdb";
	    open ( OF, ">$file") ||
		die "Cno $file: $!.\n";
	    print OF $outstr;
	    close OF;
	    `cp frame0.pdb all_frames.pdb`;
	} else {
	    $file = "current_frame.pdb";
	    open ( OF, ">$file") ||
		die "Cno $file: $!.\n";
	    print OF $outstr;
	    close OF;

	    ( -e "pom" ) || `ln -s $cedir/pom .`;

	    $cmd = "$cedir/CE - frame0.pdb - current_frame.pdb - /tmp > current.ce";
	    system ($cmd ) && die "Error running $cmd\n";

	    $cmd = "$extr current.ce > current.aff";
	    system ($cmd ) && die "Error running $cmd\n";

	    $cmd = "$rotate current_frame.pdb current.aff > curr_rot.pdb";
	    system ($cmd ) && die "Error running $cmd\n";

	    `cat  curr_rot.pdb >> all_frames.pdb`;
	}
	$outstr  = "";
 	$reading = 0;
   } elsif (  $reading  && (/^ATOM/ || /^HETATM/) ) {
	$outstr .= $_;
    }
}
