#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: two_seq_analysis.pl <msffile> \n"; 


$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;

open ( MSF, "<$name" ) ||
    die "Cno: $name  $!\n";
	

while ( <MSF>) {
    last if ( /\/\// );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $seqs{$seq_name} ){
	$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;

$ctr = 0;
foreach $seq_name ( keys %seqs ) {
    $ctr++;
}

if ( $ctr>2) {
    printf "can't analyze more than 2 seqs.\n";
    exit (1);
}

%similarto = ( 'G','G', 'A','A', 'V','V', 'L','L', 'I','I',
               'M','M', 'P','P', 'F','F', 'S','S', 'T','T', 
	       'D','D', 'E','E', 'K','K', 'R','R', 'H','H',
	       'N','N', 'Y','Y', 'Q','Q', 'W','W', 'C','C',
	       '-','-', '.', '.');

	$similarto{'I'} = 'V';
	$similarto{'S'} = 'T';
	$similarto{'D'} = 'E';
	$similarto{'K'} = 'R';
	$similarto{'Q'} = 'N';
	$similarto{'.'} = '.';



$ctr = 0;
foreach $seq_name ( keys %seqs ) {
    @seq = split ('', $seqs{$seq_name});
    foreach $pos ( 0 .. $#seq) {
	$array[$ctr][$pos] = $seq[$pos];
    }
    #$names[$ctr] = $seq_name;
    $ctr++;
}
$max_pos = $#seq;

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


