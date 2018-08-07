#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( @ARGV == 2  ) ||
    die "Usage: $0   <pdb_file>  <new_start_number>.\n";

($pdbfile, $start_no)  = @ARGV;


open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";

$model_no = $start_no;
while ( <IF> ) {
    if ( /^MODEL\s+(\d+)/ ) {
       print "MODEL  $model_no\n";
       $model_no += 1;
    } else {
        print;
    }

}
