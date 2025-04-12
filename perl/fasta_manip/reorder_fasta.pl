#! /usr/bin/perl -w
use Getopt::Std;
use IO::Handle;         #autoflush
# FH -> autoflush(1);
@ARGV >2 ||
    die "Usage: extr_seqs_from_fasta.pl  <name_list_file> <in_file>  <out_file>  .\n"; 

$list  = $ARGV[0]; 
$fasta = $ARGV[1]; 
$outfile = $ARGV[2]; 

(-e $list) || die "$list not found.\n";

@temp = split "\n", `cat $list`;
@list = ();
foreach (@temp) {
    @aux = split;
    push @list, $aux[0];
}



open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

while ( <FASTA> ) {
    next if ( !/\S/);
    chomp;
    if (/^>\s*(.+)/ ) {
	$name = $1;
	$sequence{$name} = "";
    } else  {
	$sequence{$name} .= $_."\n";
    } 
 
}
close FASTA;



open (OUTF, ">$outfile") ||
    die "Cno $outfile: $!\n";

foreach $name (@list) {
    defined $sequence{$name} || next;
    print OUTF  ">$name \n";
    print OUTF $sequence{$name};
}
close OUTF;

exit  0;
