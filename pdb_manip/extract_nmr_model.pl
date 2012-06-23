#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( @ARGV == 2  ) ||
    die "Usage: extract_nmr_model.pl   <pdb_file>  <model_no>.\n";

($pdbfile, $model_no)  = @ARGV;	


open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$reading = 0;

while ( <IF> ) {
    if ( /^MODEL\s+(\d+)/ ) {
       ($1 == $model_no) && ($reading = 1);
    } elsif ( $reading  &&  ($_=~/^ENDMDL/ || $_=~/^TER/)  ) {
	last;
    } elsif (  $reading  && ($_=~/^ATOM/ || $_=~/^HETATM/) ) {
	print;
    }
}
