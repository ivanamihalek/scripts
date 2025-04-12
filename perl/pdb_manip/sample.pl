#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( @ARGV == 2 ) ||
    die "Usage: $0  <pdb_file> <restraints_file>.\n";

($pdbfile, $restr_file)  = @ARGV;	


open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$reading = 0;
$outstr = "";
while ( <IF> ) {
    if ( /^MODEL\s+(\d+)/ ) {
	# here we just store the model/frame number
       $model_no = $1;
       $reading  =  1;
       $outstr   = $_;
    } elsif ( $reading  &&  (/^ENDMDL/ || /^TER/)  ) {
	# the processing of restraints comes here
 	$reading = 0;
   } elsif (  $reading  && (/^ATOM/ || /^HETATM/) ) {
       # coordinate parsing -- here
       $name = substr $_,  12, 4 ;  $name =~ s/\s//g; 
       $name =~ s/\*//g; 
       $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
       $res_seq  = substr $_, 22, 5;  $res_seq=~ s/\s//g;
       $res_name = substr $_,  17, 4; $res_name=~ s/\s//g;
    }
}

close IF
