#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[0] ) ||
    die "Usage: $0  <pdb_name> <renumber table>\n".
    "  renumber table: old_res_chain  old_res_id  new_res_chain  new_res_id\n";

$pdbfile =  $ARGV[0];
$renumfile =  $ARGV[1];


$filename = $renumfile;
open ( IF, "<$filename" ) || die "Cno $filename: $!.\n";
while ( <IF> ) {
    next if ( ! /\S/ ) ;
    chomp;
    @aux = split;
    $new_resid{$aux[0]."_".$aux[1]} = $aux[2]."_".$aux[3];
}
close IF;



$filename = $pdbfile;
open ( IF, "<$filename" ) || die "Cno $filename: $!.\n";



while ( <IF> ) {

    if ( ! /^ATOM/ ) {
	print;
	next;
    }
    $name = substr $_,  12, 4;     $name =~ s/\s//g; 
    $name =~ s/\*//g; 
    $alt_loc  = substr $_, 16, 1;  $alt_loc =~ s/\s//g;
    $chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
    $res_seq  = substr $_, 22, 4;  $res_seq =~ s/\s//g;

    $newline = $_;
    if (defined $new_resid{$chain_id."_".$res_seq} ) {
	($new_chain, $new_res)  = split "_", $new_resid{$chain_id."_".$res_seq};
	substr( $newline,  21, 1) = $new_chain;
	$formatted = sprintf "%4d", $new_res;
	substr( $newline,  22, 4) = $formatted;
    }
    print $newline;

}
close IF;
