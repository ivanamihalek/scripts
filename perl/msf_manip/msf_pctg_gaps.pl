#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[0]  ||
    die "Usage: msf_pctg_gaps.pl  <msf_file_name>.\n"; 

$msf   =  $ARGV[0];
open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

# read in the msf file:
while ( <MSF> ) {
    last if ( /\/\//);
}

%sequence = ();
do {
    if ( /\w/ ) {
	@aux = split;
	$name = $aux[0];
	$aux_str = join ('', @aux[1 .. $#aux] );
	if ( defined $sequence{$name} ) {
	    $sequence{$name} .= $aux_str;
	} else {
	    $sequence{$name}  = $aux_str;
	}
		
    } 
} while ( <MSF>);




# turn the msf into a table (first index= sequence, 2bd index= position
$seq = 0;
$gaps = 0;
foreach $name ( keys %sequence ) {
    $gaps += ( $sequence{$name} =~ s/\./\-/g );
    $seq ++;
}
$no_seqs = $seq;   
$length = length  $sequence{$name};

$pctg = $gaps/($no_seqs*$length );

printf " %8.3f \n", $pctg;
