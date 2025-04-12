#! /usr/bin/perl -w
sub formatted_sequence ( @);


while ( <> ) {
    next if ( !/\S/ );
    if ( /^>/ )  {
	print;
	next;
    }
    chomp;
    $line = $_;
    $line =~ s/\s//g;
    $seq .= $line;
 
}


$seq =~ tr/acgtuACGTU/TGCAATGCAA/;   
$rev = reverse $seq;

print formatted_sequence($rev);
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
