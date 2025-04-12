#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: fasta2uniprot.pl  <fasta_file>.\n"; 

$fasta =  $ARGV[0]; 
$database = "/home/pine/databases/nr";
$blast = "/home/i/imihalek/bin/blast/blastall";

$EVALUE = 1.e-50;

sub formatted_sequence ( @);
sub do_blast ( @ );

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {
    chomp;
    if (/^>\s*(.+)/ ) {

	$name = $1;
	$name =~ s/\s//g;
	push @names,$name;
	$sequence{$name} = "";
    } else  {
	s/\-/\./g;
	s/\#/\./g;
	s/\s//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close FASTA;

foreach $name ( @names ) {
    print "\n $name\n";
    do_blast ( $sequence{$name}, $name,$database, $blast, 8, "$name.nr.blast");
}


######################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 


######################################################
sub do_blast ( @ ) {
    my ($seq, $name, $database, $blast, $output_format, $blastfile) =  @_;
    my $command;
    my $seqfile = "tmp";

    (  -e  $blastfile  &&  -s $blastfile)  && return;

    ( defined $seq) || die  "Error: Undefined sequence in do_blast()";
    open ( OF, ">$seqfile") || die "Error: Cno $seqfile:$!.";
    print OF "> $name\n";
    print OF formatted_sequence ($seq), "\n";
    close OF;
    
     
    $command =  "$blast -p blastp  -d $database -i $seqfile -o $blastfile   -m $output_format";
    $command .= " -e $EVALUE";
    
    ( system $command)  && die "Error: $command\n error running blast."; 
    
}
