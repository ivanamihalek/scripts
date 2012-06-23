#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0]  ) ||
    die "Usage: pdb_chain_rename.pl   <pdb_file> [<biomt number>].\n";

$pdbfile = $ARGV[0];

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";


    
while ( <IF> ) {

    next if ( ! /^REMARK/ || ! /BIOMT/  );
    if ( defined $ARGV[1] ) {
	next if (substr ($_, 22, 1 ) ne $ARGV[1] );
    }
    
    
    print substr $_, 23;

}

close IF;
