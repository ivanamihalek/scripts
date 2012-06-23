#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[1]  ||
    die "Usage: restrict_msf_to_query.pl  <msf_file_name>  <positions file>.\n"; 


$msf   =  $ARGV[0];
$positions_file =  $ARGV[1];


open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

# read in the msf file:
while ( <MSF> ) {
    last if ( /\/\//);
}

%sequence = ();
@names = ();
do {
    if ( /\w/ ) {
	@aux = split;
	$name = $aux[0];
	$aux_str = join ('', @aux[1 .. $#aux] );
	if ( defined $sequence{$name} ) {
	    $sequence{$name} .= $aux_str;
	} else {
	    $sequence{$name}  = $aux_str;
	    push @names, $name;
	}
		
    } 
} while ( <MSF>);
close MSF;

# readin positions

open ( POS, "<$positions_file") ||
    die "Cno $positions_file: $!\n";

while ( <POS> ) {
    next if ( ! /\S/ );
    chomp;
    @aux = split;
    $pos = $aux[0];
    $pos =~ s/\s//g;
    $pos -= 1;
    $selected{$pos} = 1;
}

close POS;


# turn the msf into a table (first index= sequence, 2nd index= position

$seq = 0;
foreach $name ( @names ) {
    @aux = split '', $sequence{$name};
    foreach $pos ( 0 .. $#aux ) {
	$array[$seq][$pos] = $aux[$pos];
    }
    $seq++;    
}

$no_seqs = $seq;   # number of seqs
$max_seq = $seq-1; # max index a seq can have
$max_pos = $#aux;  # max index a position can have

# sanity check:
$no_seqs || die "Error in sift.pl: no seqs found.\n"; 


foreach $pos ( 0 .. $max_pos ) {
    
    if ( defined $selected{$pos}) {
	$delete[$pos] = 0;
    } else {
	$delete[$pos] = 1;
    }
}

foreach $seq ( 0 .. $max_seq ) {
    $seq_new[$seq] = "";
}

foreach $seq ( 0 .. $max_seq ) {
    foreach $pos ( 0 .. $max_pos ) {
	if ( ! $delete[$pos] ) {
	    $seq_new[$seq] .= $array[$seq][$pos];
	}
    }
}

$deleted = 0;
foreach $pos ( 0 .. $max_pos ) {
    $deleted += $delete[$pos];
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
foreach $name ( @names ) {
    printf NEW_MSF (" Name: %-40s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $new_length);
}
print NEW_MSF "\n//\n\n\n\n";

for ($j=0; $j  < $new_length; $j += 50) {
    $seq = 0;
    foreach $name ( @names ) {
	printf NEW_MSF "%-40s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $new_length ) {
		printf NEW_MSF "%-10s ",   substr ($seq_new[$seq], $j+$k*10 );
		last;
	    } else {
		printf NEW_MSF "%-10s ",   substr ($seq_new[$seq], $j+$k*10, 10);
	    }
	}
	print NEW_MSF "\n";
	$seq++;
    } 
    print NEW_MSF "\n";
}

$max_pos ++;
printf "removed $deleted columns   (out of $max_pos)\n";


close NEW_MSF;
