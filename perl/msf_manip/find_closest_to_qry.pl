#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[1]  ||
    die "Usage: find_closest_to_qry.pl  <msf_file_name>  <query>.\n"; 


$msf   =  $ARGV[0];
$query_name =  $ARGV[1];



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


# turn the msf into a table (first index= sequence, 2nd index= position)
$query_seq = -1;
$seq = 0;
foreach $name ( keys %sequence ) {
    @aux = split '', $sequence{$name};
    foreach $pos ( 0 .. $#aux ) {
	$array[$seq][$pos] = $aux[$pos];
    }
    $names[$seq] = $name;
    if ( defined $query_name ) {
	if ( $name =~ $query_name && $query_name =~ $name) {
	    $query_seq = $seq;
	}
    }
    $seq++;
    
}

if ( $query_seq < 0) {
    die "$query_name  name not found in the almt $msf\n"; 
}

$no_seqs = $seq;   # number of seqs
$max_seq = $seq-1; # max index a seq can have
$max_pos = $#aux;  # max index a position can have

# sanity check:
$no_seqs || die "Error in sift.pl: no seqs found.\n"; 

$max_id = 0;
$max_seq = $query_seq;

$len1 = 0;
for $pos ( 0 .. $max_pos-1) {
    ($array[$query_seq][$pos] eq '.' ) || $len1++;
}
if ( ! $len1 ) {
    die "Query of length zero (?).\n";
}

# calculate similarity
for $seq2 ( 0 .. $no_seqs-1) {
    next if ( $seq2 == $query_seq);
    $len2 = 0;
    for $pos ( 0 .. $max_pos-1) {
	($array[$seq2][$pos] eq '.' ) || $len2++;
    }
    if ( ! $len2 ) {
	next;
    }
	
    $common = 0;
    for $pos ( 0 .. $max_pos-1) {
	if ($array[$query_seq][$pos] ne '.' &&
	    $array[$query_seq][$pos] eq $array[$seq2][$pos] )  {
	    $common ++;
	}
    }
    $id =  $common/$len1;
    if ( $id > $max_id ) {
	$max_id = $id;
	$max_seq = $seq2;
    }
}

$pct = int ( 100*$max_id);
print "the closest to $names[$query_seq] is $names[$max_seq]  ($pct% id).\n";


