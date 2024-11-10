#! /usr/bin/perl -w
use strict;
use warnings;
use IO::Handle; #autoflush
# takes a single seq in fasta format

sub formatted_sequence ( @);
sub process_seq ( @);

( @ARGV >= 3 ) ||
    die "Usage: $0  <afa file>  <begin> <end>.\n";

$file     = shift @ARGV;

%ranges   = @ARGV;

open ( IF, "<$file") || die "Cno $file: $!.\n";

$seq = "";
$reading = 0;
while ( <IF> ) {
    next if ( !/\S/ );
    if ( /^>(.+)\// ) {
        ( $seq ) && process_seq ($seq);
        $seq = "";
        $name = $1;
    } else {
        chomp;
        $line = $_;
        $line =~ s/\s//g;
        $seq .= $line;
    }

}

( $seq ) && process_seq ($seq);
######################################################

sub process_seq ( @) {
    my $sequence = $_[0];
    my $subseq = "";
    my ($begin, $end);
    my $first = 1;

    while( ($begin, $end) = each(%ranges)) {
        if ( $first ) {
            $first = 0;
        } else {
            $subseq .= "---";
        }
        $subseq .= substr $seq, ($begin-1), ($end-$begin+1);
    }

    print ">$name\n";
    print formatted_sequence($subseq  );
    print "\n";
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
