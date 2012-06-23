#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( @ARGV >= 4  ) ||
    die "Usage: $0   <pdb_file_template>  <pdb_file_trajectory> ".
    "<from> <to> [<chain>].\n";

($template, $trajectory, $from, $to)  = @ARGV;	

$chain = "";
if ( @ARGV == 5 ) {
    $chain = pop @ARGV;
} 

$outfile = "refitted.pdb";

$cedir  = "/home/ivanam/downloads/ce_distr";
$extr   = "/home/ivanam/perlscr/extractions/matrix_from_ce.pl";
$rotate = "/home/ivanam/perlscr/pdb_manip/pdb_affine_tfm.pl";
$extr_pdb_region = "/home/ivanam/perlscr/pdb_manip/pdb_extract_region.pl";

$cmd = "$extr_pdb_region $template $from $to > template_substr.pdb";
(system $cmd ) && die "error running $cmd\n";

( -e $outfile) && `rm $outfile`;
`touch $outfile`;

open ( IF, "<$trajectory") ||
    die "Cno $trajectory: $!.\n";

$reading = 0;
$outstr = "";
$substr = "";
while ( <IF> ) {

    if ( /^MODEL\s+(\d+)/ ) {

       #$model_no = $1;
       $reading  =  1;
       $outstr   = $_;

    } elsif ( $reading  &&  (/^ENDMDL/ || /^TER/)  ) {

	$outstr .= "ENDMDL\n";

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

	$cmd = "$cedir/CE - template_substr.pdb - current_substr.pdb - /tmp > current.ce";
	system ($cmd ) && die "Error running $cmd\n";

	$cmd = "$extr current.ce > current.aff";
	system ($cmd ) && die "Error running $cmd\n";
	
	( -z "current.aff") && die "Error using ce - check current.ce\n";

	$cmd = "$rotate current_frame.pdb current.aff > curr_rot.pdb";
	system ($cmd ) && die "Error running $cmd\n";

	`cat  curr_rot.pdb >> $outfile`;
	    
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
`rm  template_substr.pdb`;
`rm current.ce current.aff`;
