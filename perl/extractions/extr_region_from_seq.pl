#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# takes a single seq in fasta format

sub formatted_sequence ( @);

( defined ($ARGV[2]) ) || 
    die "Usage: extr_region_from_seq.pl <seq file> <qry name>  <begin> <end>.\n";

($file, $qry_name,  $begin, $end) = @ARGV;
open ( IF, "<$file") || die "Cno $file: $!.\n";

$seq = "";
$reading = 0;
while ( <IF> ) {
    next if ( !/\S/ );
    if ( /^>\s*(\w+)/ ) {
	$name = $1;
	if ( $name eq $qry_name) {
	    $reading = 1;
	}
    } elsif ($reading) {
	chomp;
	$line = $_;
	$line =~ s/\s//g;
	$seq .= $line;
    }

}



print "> $name\_$begin\_$end\n";
print formatted_sequence( substr $seq, ($begin-1), ($end-$begin+1) );
print "\n";

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
