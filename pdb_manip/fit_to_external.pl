#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

##########################################################
# check the input arguments
( @ARGV >= 3  ) ||
    die "Usage: $0   <pdb_file>  <residue_list_file> <external pdb>.\n";

($pdbfile, $reslist_fnm, $external_pdb)  = @ARGV;	

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

`touch $out_fnm`;

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

	$file = "current_frame.pdb";
	open ( OF, ">$file") || die "Cno $file: $!.\n";
	print OF $outstr;
	close OF;

	# fitter assumes that the structures are approximately aligned
	# need to take care of thatw

	$cmd = "$fitter current_frame.pdb $external_pdb $reslist_fnm current";
	system ($cmd ) && die "Error running $cmd\n";
	print $cmd, "\n";
	exit(1);
	`echo MODEL $model_no >> $out_fnm`;
	`grep -v REMARK current.rot.pdb >> $out_fnm`;
	`echo ENDMDL >> $out_fnm`;
	    
	$outstr  = "";
	$reading = 0;

    }
}

`rm  current_frame.pdb current.rot.pdb`;
