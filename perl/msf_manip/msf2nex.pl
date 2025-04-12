#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: msf2nex.pl <msffile> \n"; 


$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;

open ( MSF, "<$name" ) ||
    die "Cno: $name  $!\n";
	

while ( <MSF>) {
    last if ( /\/\// );
    last if ( /CLUSTAL FORMAT for T-COFFEE/ );
}
$no_seq = 0;
@seqnames = ();
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $seqs{$seq_name} ){
	$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
	push @seqnames, $seq_name;
	$no_seq ++;
    }
}

close MSF;

#find distance btw seqeunces - note that this need some elaboration :}
foreach $i 

( 0 .. $no_seq-1) {
    $distance[$i][$i] = 0.0;
    $seq1 = $seqs{ $seqnames[$i]};
    foreach $j( 0 .. $i-1) {
	$distance[$i][$j] = 0.0;
	$seq2 = $seqs{ $seqnames[$j]};
	foreach $pos (0 .. length ($seq1)) {
	    $char1 = substr ($seq1, $pos, 1);
	    $char2 = substr ($seq2, $pos, 1);
	    if (  ! ($char1 eq $char2 ) ){
		$distance[$i][$j] +=1;
	    }
	}
	$distance[$i][$j] /= length ($seq1);
    }
}


	

print  "#NEXUS\n\n";
print  "BEGIN taxa;\n";
printf  "\t  DIMENSIONS ntax= %d;\n", $no_seq;
printf  "\t  TAXLABELS\n";
foreach $seq_name ( @seqnames ) {
   print  "\t\t $seq_name\n";
}
printf  "\t  ;\n";
printf  "END;\n\n";

print  "BEGIN distances;\n";
printf  "\t  DIMENSIONS ntax= %d;\n", $no_seq;
printf  "\t  FORMAT\n";
printf  "\t  triangle=LOWER\n";
printf  "\t  diagonal\n";
printf  "\t  labels\n";
printf  "\t  missing=?\n";
printf  "\t ;\n";
printf  "\t MATRIX\n";

foreach $i ( 0 .. $no_seq-1) {
    printf  "\t %-30s  ",  $seqnames[$i];
    foreach $j( 0 .. $i) {
	printf   "%6.3f", 	$distance[$i][$j];
    } 
    printf  "\n";
} 
printf  "\t  ;\n";
printf  "END;\n";

 


