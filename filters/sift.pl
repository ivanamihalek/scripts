#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[0]  ||
    die "Usage: sift.pl  <msf_file_name>  [<cutoff_percentage>] [<protected sequence>].\n"; 

$cutoff = 1.0;

if ( defined $ARGV[1] ) {
    $cutoff =  $ARGV[1];
} 

if ( defined $ARGV[2] ) {
    $protected_name =  $ARGV[2];
} 


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




# turn the msf into a table (first index= sequence, 2nd index= position
$protected_seq = 0;
$seq = 0;
foreach $name ( keys %sequence ) {
    @aux = split '', $sequence{$name};
    foreach $pos ( 0 .. $#aux ) {
	$array[$seq][$pos] = $aux[$pos];
    }
    $names[$seq] = $name;
    if ( defined $protected_name ) {
	if ( $name =~ $protected_name && $protected_name =~ $name) {
	    $protected_seq = $seq;
	}
    }
    $seq++;
    
}
if ( defined $protected_name ) {
    if ( ! $protected_seq) {
	die "$protected_name  name not found in the almt $msf\n"; 
    }
}
$no_seqs = $seq;   # number of seqs
$max_seq = $seq-1; # max index a seq can have
$max_pos = $#aux;  # max index a position can have

# sanity check:
$no_seqs || die "Error in sift.pl: no seqs found.\n"; 


# find positions which are mostly gap
foreach $pos ( 0 .. $max_pos ) {
    $gap_ctr = 0;
    foreach $seq ( 0 .. $max_seq ) {
	if ( $array[$seq][$pos] =~ '\.' ) {
	    $gap_ctr ++;
	}
    }
    if ( $gap_ctr/($max_seq+1) >= $cutoff ){
	$mostly_gap[$pos] = 1;
    } else {
	$mostly_gap[$pos] = 0;
    }
}


if ( $protected_seq) {
    foreach $pos ( 0 .. $max_pos ) {
	if ( $array[$protected_seq][$pos] !~ '\.' ) {
	    $mostly_gap[$pos] = 0;
	}
    }
}


foreach $seq ( 0 .. $max_seq ) {
    $seq_new[$seq] = "";
}

foreach $seq ( 0 .. $max_seq ) {
    foreach $pos ( 0 .. $max_pos ) {
	if ( !$mostly_gap[$pos] ) {
	    $seq_new[$seq] .= $array[$seq][$pos];
	}
    }
}

$gapped = 0;
foreach $pos ( 0 .. $max_pos ) {
    $gapped += $mostly_gap[$pos];
}

$new_length = length $seq_new[0];

@aux = split '\.', $msf;
$newmsf = (join '.',  @aux[0.. $#aux-1]).'.sifted.'.$aux[$#aux];

open (NEW_MSF,">$newmsf") ||
    die "Cno $newmsf: $!\n";

print NEW_MSF "PileUp\n\n";
print NEW_MSF "            GapWeight: 30\n";
print NEW_MSF "            GapLengthWeight: 1\n\n\n";
printf NEW_MSF  ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$new_length) ;
foreach $seq ( 0 .. $max_seq ) {
    printf NEW_MSF (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $names[$seq], $new_length);
}
print NEW_MSF "\n//\n\n\n\n";

for ($j=0; $j  < $new_length; $j += 50) {
    foreach $seq ( 0 .. $max_seq ) {
	printf NEW_MSF "%-30s", $names[$seq];
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $new_length ) {
		printf NEW_MSF "%-10s ",   substr ($seq_new[$seq], $j+$k*10 );
		last;
	    } else {
		printf NEW_MSF "%-10s ",   substr ($seq_new[$seq], $j+$k*10, 10);
	    }
	}
	print NEW_MSF "\n";
    } 
    print NEW_MSF "\n";
}

$max_pos ++;
printf "removed $gapped columns as gapped  (out of $max_pos)\n";


close NEW_MSF;
