#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(@ARGV > 2  ) ||
    die "Usage: pdb_chain_rename.pl  ".
    " <pdb_file>   <from>  <to> [<chain_name>].\n";

($pdbfile, $from, $to) = @ARGV[0 .. 2];
if ( defined $ARGV[3] ) {
    $query_chain_name =$ARGV[3] ;
} else {
    $query_chain_name ="" ;
}

open ( IF, "<$pdbfile") ||
    die "Cno $pdbfile: $!.\n";


    
while ( <IF> ) {

    last if ( /^ENDMDL/);
    next if ( ! /^ATOM/  );
    $line = $_;
    if ( ! $query_chain_name || 
	 substr ( $line,  21, 1) eq $query_chain_name ) {
	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	next if ( $from <= $res_seq && $res_seq <= $to );
	print $line;
    }
}

close IF;
