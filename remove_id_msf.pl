#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[1]  ||
    die "Usage: restrict_msf_to_query.pl  <msf_file_name>  <protected sequence> [<id cutoff>].\n"; 


$msf   =  $ARGV[0];
$query_name =  $ARGV[1];


$cutoff = 0.98;
( defined $ARGV[2] ) &&  ($cutoff = $ARGV[2]);

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

# remove identical seqs
for $seq1 ( 0 .. $no_seqs-1){
    $delete[$seq1] = 0;
}
for $seq1 ( 0 .. $no_seqs-2){
    next if ( $delete [$seq1]);
    $len1 = 0;
    for $pos ( 0 .. $max_pos-1) {
	($array[$seq1][$pos] eq '.' ) || $len1++;
    }
    if ( ! $len1 ) {
	$delete[$seq1] = 1;
	next;
    }
    for $seq2 ( $seq1+1 .. $no_seqs-1) {
	next if ( $delete [$seq2]);
	$len2 = 0;
	$common = 0;
	for $pos ( 0 .. $max_pos-1) {
	    ($array[$seq2][$pos] eq '.' ) || $len2++;
	}
	if ( ! $len2 ) {
	    $delete[$seq2] = 1;
	    next;
	}
	
	for $pos ( 0 .. $max_pos-1) {
	    if ($array[$seq1][$pos] ne '.' &&
		$array[$seq1][$pos] eq $array[$seq2][$pos] )  {
		$common ++;
	    }
	}
	if ( $len1 <= $len2  && $common/$len1 >= $cutoff) {
	    if ( $seq1==$query_seq ) {
		$delete[$seq2] = 1;
	    } else {
		$delete[$seq1] = 1;
	    }
	   
	} elsif (  $len2 <= $len1  && $common/$len2 >= $cutoff) {
	    if ( $seq2==$query_seq ) {
		$delete[$seq1] = 1;
	    } else {
		$delete[$seq2] = 1;
	    }
	}
    }
}



@aux = split '\.', $msf;
#$newmsf = (join '.',  @aux[0.. $#aux-1]).'.pruned.'.$aux[$#aux];
$new_length = $max_pos + 1;


print  "PileUp\n\n";
print  "            GapWeight: 30\n";
print  "            GapLengthWeight: 1\n\n\n";
printf   ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$new_length) ;
foreach $seq ( 0 .. $max_seq ) {
    next if ( $delete[$seq] );
    printf  (" Name: %-15s   Len: %5d   Check: 9554   Weight: 1.00\n", $names[$seq], $new_length);
}
print  "\n//\n\n\n\n";

for ($j=0; $j  < $new_length; $j += 50) {
    foreach $seq ( 0 .. $max_seq ) {
	next if ( $delete[$seq] );
	printf  "%-40s", $names[$seq];
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $new_length ) {
		printf  "%-10s ",   substr ($sequence{$names[$seq]}, $j+$k*10 );
		last;
	    } else {
		printf  "%-10s ",   substr ($sequence{$names[$seq]}, $j+$k*10, 10);
	    }
	}
	print  "\n";
    } 
    print  "\n";
}


