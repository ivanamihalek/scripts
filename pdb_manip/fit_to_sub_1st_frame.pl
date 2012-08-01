#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( @ARGV >= 3  ) ||
    die "Usage: $0   <pdb_file> <from> <to> [<chain>].\n";

($pdbfile, $from, $to)  = @ARGV;	

$chain = "";
if ( @ARGV == 4 ) {
    $chain = pop @ARGV;
} 

$cedir  = "/home/ivanam/downloads/ce_distr";
$extr   = "/home/ivanam/perlscr/extractions/matrix_from_ce.pl";
$rotate = "/home/ivanam/perlscr/pdb_manip/pdb_affine_tfm.pl";

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$reading = 0;
$outstr = "";
$substr = "";

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

	    $file = "substr0.pdb";
	    open ( OF, ">$file") ||
		die "Cno $file: $!.\n";
	    print OF $outstr;

	} else {

	    $file = "current_frame.pdb";
	    open ( OF, ">$file") ||
		die "Cno $file: $!.\n";
	    print OF $outstr;
	    close OF;

	    $file = "current_substr.pdb";
	    open ( OF, ">$file") ||
		die "Cno $file: $!.\n";
	    print OF $substr;
	    close OF;

	    ( -e "pom" ) || `ln -s $cedir/pom .`;

	    $cmd = "$cedir/CE - substr0.pdb - current_substr.pdb - /tmp > current.ce";
	    system ($cmd ) && die "Error running $cmd\n";

	    $cmd = "$extr current.ce > current.aff";
	    system ($cmd ) && die "Error running $cmd\n";

	    $cmd = "$rotate current_frame.pdb current.aff > curr_rot.pdb";
	    system ($cmd ) && die "Error running $cmd\n";

	    `cat  curr_rot.pdb >> all_frames.pdb`;
	    
	}
	$outstr  = "";
	$substr  = "";
 	$reading = 0;

   } elsif (  $reading  && (/^ATOM/ || /^HETATM/) ) {
       # save the whole struct
       $outstr .= $_;

       # separately save the substruct we will be fitting to
       $res_seq   = substr $_, 22, 4;  $res_seq=~ s/\s//g;
       $chainname = substr $_, 21, 1; 
       next if ( $chain  &&  ($chain ne $chainname));
       if ( $res_seq >= $from &&  $res_seq <= $to) {
	   $substr .= $_;
       }
    }
}

`rm current_substr.pdb current_frame.pdb curr_rot.pdb`;
`rm frame0.pdb substr0.pdb`;
`rm current.ce current.aff`;
