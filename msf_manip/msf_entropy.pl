#! /usr/gnu/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$MAX_GAPS = 0.95;
 
defined $ARGV[0]  ||
    die "Usage: msf2table.pl  <msf_file_name> [<max_gap_percntage>] [<query>].\n"; 

$msf   =  $ARGV[0];
open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

if ( defined $ARGV[1]) {
    $MAX_GAPS = $ARGV[1];
}

$query_name = "";
if ( defined $ARGV[2]) {
    $query_name = $ARGV[2];
}

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
$query = 0;
$seq = 0;
foreach $name ( keys %sequence ) {
    if ( $query_name  && $name eq $query_name ) {
	$query = $seq;
    }
    @aux = split '', $sequence{$name};
    foreach $pos ( 0 .. $#aux ) {
	$array[$seq][$pos] = $aux[$pos];
    }
    #$names[$seq] = $name;
    $seq++;
    
}
$no_seqs = $seq;   # number of seqs
$max_seq = $seq-1; # max index a seq can have
$max_pos = $#aux;  # max index a position can have

# sanity check:
$no_seqs || die "Error msf2table.pl: no seqs found.\n";

#find percentage of gaps 
for $pos ( 0 .. $max_pos) {
    $no_gaps = 0; ;
    for $seq ( 0 .. $max_seq) {
	$aa = $array[$seq][$pos];
	if ( $aa eq "." ) {
	    $no_gaps++;
	}
    }
    if ( $no_gaps > $MAX_GAPS*$no_seqs ) {
	$gapped{$pos} = 1; 
    } else {
	$gapped{$pos} = 0 
    }
}
$avg = 0;
$avg_sq  = 0;
$ctr = 0;
for $pos ( 0 .. $max_pos) {
    next if ( $gapped{$pos});
    %freq = () ;
    for $seq ( 0 .. $max_seq) {
	$aa = $array[$seq][$pos];
	if  ( defined $freq{$aa} ) {
	    $freq{$aa} ++;
	} else {
	    $freq{$aa} = 1;
	}
    }
    $entropy{$pos} = 0;
    for $aa ( keys %freq ) {
	$freq{$aa} /=  $no_seqs;
	$entropy{$pos}  -=  $freq{$aa}* log ($freq{$aa});
    }
    $avg += $entropy{$pos};
    $avg_sq += $entropy{$pos}*$entropy{$pos};
    
    $ctr++;
}
$avg /= $ctr;
$avg_sq /= $ctr;
$sigma =  $avg_sq - $avg*$avg;
$sigma = sqrt ( $sigma );

@pos_sorted = sort HashByValue  (keys(%entropy));

for $pos ( @pos_sorted ) {
    next if ( $gapped{$pos});
    $z =  ($entropy{$pos} - $avg )/$sigma;
    printf " %5d   %s  %8.3f  %8.3f \n", $pos+1, $array[$query][$pos], $entropy{$pos}, $z;
}



sub  HashByValue {
    $entropy{$a} <=> $entropy{$b};
}
