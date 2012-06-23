#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( @ARGV >=3  ) ||
    die "Usage: extract_nmr_model.pl   <pdb_file>  <model_from>  <model_to>.\n";

($pdbfile, $model_from, $model_to)  = @ARGV;	


open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$reading = 0;

while ( <IF> ) {
    if ( /^MODEL\s+(\d+)/ ) {
       if ($1 >= $model_from &&  $1 <= $model_to ) {
	   $reading = 1;
	   print;
       }
    } elsif ( $reading  &&  (/^ENDMDL/)  ) {
	print;
	$reading = 0;
    } elsif ( $reading  && (/^ATOM/ || /^HETATM/ || /^TER/) ) {
	print;
    }
}
