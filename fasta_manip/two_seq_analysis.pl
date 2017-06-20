#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: two_seq_analysis.pl <afa file> \n"; 

$name = $ARGV[0] ;

open ( AFA, "<$name" ) ||
    die "Cno: $name  $!\n";
	
while ( <AFA> ) {
    next if ( !/\S/);
    chomp;
    if (/^>\s*(.+)/ ) {
	$name = $1;
	push @names,$name;
	$sequence{$name} = "";
    } else  {
	s/\./\-/g;
	s/\#/\-/g;
	s/\s//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close AFA;


if ( @names>2) {
    printf "can't analyze more than 2 seqs.\n";
    exit (1);
}


print "@names\n";

%similarto = ( 'G','G', 'A','A', 'V','V', 'L','L', 'I','I',
               'M','M', 'P','P', 'F','F', 'S','S', 'T','T', 
	       'D','D', 'E','E', 'K','K', 'R','R', 'H','H',
	       'N','N', 'Y','Y', 'Q','Q', 'W','W', 'C','C',
	       '-','-', '.', '.', 'Z', 'Z');

$similarto{'I'} = 'V';
$similarto{'S'} = 'T';
$similarto{'D'} = 'E';
$similarto{'K'} = 'R';
$similarto{'Q'} = 'N';



$ctr = 0;
foreach $seq_name ( @names ) {
    @seq = split ('', $sequence{$seq_name});
    foreach $pos ( 0 .. $#seq) {
	$array[$ctr][$pos] = $seq[$pos];
    }
    #$names[$ctr] = $seq_name;
    $ctr++;
}
$max_pos = $#seq;

print "max pos: $max_pos\n";
$max_pos>0 || die "No seq of non-zero length given (?!)\n";

$pid= 0;
$sim = 0;
$eff_length = 0;
$len[0] = 0; $len[1] = 0;
for $pos (0 .. $max_pos) {
    if ( $array[0][$pos] !~ '\.' ) {
	$len[0] ++;
    }
    if ( $array[1][$pos] !~ '\.' ) {
	$len[1] ++;
    }
    next if ( $array[0][$pos] =~ '\.' || $array[1][$pos] =~ '\.' );
    $eff_length++;
    if ( $array[0][$pos] =~ $array[1][$pos] ) {
	$pid ++;
    }
    if ( $similarto {$array[0][$pos]} =~ $similarto  {$array[1][$pos]} ) {
	$sim ++;
    }

}

if ( $eff_length ) {
    $pid /= $eff_length;    
    $sim /= $eff_length;
} else {
    $pid  = 0;    
    $sim  = 0;    
}



#print " $names[0]  $len[0]    $names[1]  $len[1]    ";
printf " frac1    %6.3f   frac2    %6.3f    identity  %6.3f    similarity  %6.3f     \n", 
    $eff_length/$len[0], $eff_length/$len[1], $pid, $sim;


