#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

##########################################################
# check the input arguments
( @ARGV >= 2  ) ||
    die "Usage: $0   <pdb_file>  <residue_list_file>.\n";

($pdbfile, $reslist_fnm)  = @ARGV;	

foreach ($pdbfile, $reslist_fnm) {
    -e $_ || die "$_ not found.\n";
}


##########################################################
# check the dependencies
$user_home = "/home/ivanam/";
(-e  $user_home)  || ($user_home = "/Users/ivana/");
(-e  $user_home)  || die "User home directory not found.\n";

$fitter = "$user_home/c-utils/fitter/fitter";

foreach ($user_home, $fitter) {
    -e $_ || die "$_ not found.\n";
}


##########################################################
# new name for the output file
$out_fnm = $pdbfile;
$out_fnm =~ s/.pdb$//;
$out_fnm .= ".fitted.pdb";

##########################################################
# loop over models is the pdb file
open ( IF, "<$pdbfile") ||  die "Cno $pdbfile: $!.\n";

$reading = 0;
$outstr = "";
$first_model = 1;

while ( <IF> ) {
    
    ####
    # start of a new model
    if ( /^MODEL\s+(\d+)/ ) {
       $model_no = $1;
       $reading  =  1;
       $outstr   = $_;
   
    ####
    # reading ...
    } elsif (  $reading  && (/^ATOM/ || /^HETATM/) ) {

       $outstr .= $_;

    ####
    # end of a model: process
    } elsif ( $reading  &&  (/^ENDMDL/ || /^TER/)  ) {

	$outstr .= "ENDMDL\n";

	# special treatment for the first model/frame: just output
	if ($first_model) {
	    
	    $first_model = 0;

	    $file = "frame0.pdb";
	    open ( OF, ">$file") || die "Cno $file: $!.\n";
	    print OF $outstr;
	    close OF;
	    
	    `cp frame0.pdb $out_fnm`;

	# for all other models/frames
	} else {

	    $file = "current_frame.pdb";
	    open ( OF, ">$file") || die "Cno $file: $!.\n";
	    print OF $outstr;
	    close OF;

	    $cmd = "$fitter current_frame.pdb frame0.pdb $reslist_fnm current";
	    system ($cmd ) && die "Error running $cmd\n";
	    `echo MODEL $model_no >> $out_fnm`;
	    `grep -v REMARK current.rot.pdb >> $out_fnm`;
	    `echo ENDMDL >> $out_fnm`;
	    
	}
	$outstr  = "";
	$reading = 0;

    }
}

`rm frame0.pdb current_frame.pdb current.rot.pdb`;
