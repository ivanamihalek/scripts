#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[0]  ||
    die "Usage: msf2table.pl  <msf_file_name> .\n"; 


$msf   =  $ARGV[0];

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
	    push @names, $name;
	    $sequence{$name}  = $aux_str;
	}
		
    } 
} while ( <MSF>);




# turn the msf into a table (first index= sequence, 2bd index= position
$seq = 0;
foreach $name ( @names ) {
    @aux = split '', $sequence{$name};
    foreach $pos ( 0 .. $#aux ) {
	$array[$seq][$pos] = $aux[$pos];
	if ( $aux[$pos] !~ /[\.\-]/ ) {
	    (defined  $counter[$seq]) || ($counter[$seq] = 0);
	    $counter[$seq] ++;
	    $seqno[$seq][$pos] = $counter[$seq];
	} else {
	    $seqno[$seq][$pos] = "-";
	}
    }
    $seq++;
    
}
$no_seqs = $seq;   # number of seqs
$max_seq = $seq-1; # max index a seq can have
$max_pos = $#aux;  # max index a position can have

# sanity check:
$no_seqs || die "Error msf2table.pl: no seqs found.\n"; 


foreach  $name(@names) {
    printf "%8s", substr $name, 0, 6;
}
    print "\n";

foreach $pos ( 0 .. $max_pos ) {
    foreach  $seq (0 .. $max_seq) {
	printf "%4s  %s ",  $seqno[$seq][$pos], $array[$seq][$pos];
    }
    print "\n";
}
