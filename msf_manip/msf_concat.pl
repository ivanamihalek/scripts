#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[2]  ||
    die "Usage: msf_concat.pl <names> <msf1> <msf2> [<msf3>  <msf4> ...]\n"; 

$filename = $ARGV[0];
open ( FH, "<$filename" ) ||
    die "Cno $filename: $!.\n";
#slurp in the input as a single string
undef $/;
$_ = <FH>;
$/ = "\n";
close FH;
@seq_names = split '\n';

foreach $name  ( @ARGV[ 1 .. $#ARGV]) {

    open ( MSF, "<$name" ) ||
	die "Cno: $name  $!\n";
	

    while ( <MSF>) {
	last if ( /\/\// );
	last if ( /CLUSTAL FORMAT for T-COFFEE/ );
    }
    while ( <MSF>) {
	next if ( ! (/\w/) );
	chomp;
	@aux = split;
	$seq_name = shift @aux;
	if ( defined $seqs{$seq_name} ){
	    $seqs{$seq_name} .= join ('', @aux);
	    #print;
	    #print "@aux\n";
	} else { 
	    $seqs{$seq_name}  = join ('', @aux);
	}
    }
    close MSF;

}

#sanity check
foreach $seq_name ( @seq_names ) {
    $seqlen = length $seqs{$seq_name};
    if ( defined $oldlen ) {
	if (  $oldlen != $seqlen  ) {
	    die "Seqs of uneven length: $oldname (length $oldlen) and  $seq_name  (length $seqlen).\n";
	}
    }
    $oldlen =  $seqlen ;
    $oldname = $seq_name;
}


#output
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: N    Check:  9554   .. \n\n",$seqlen) ;
foreach $seq_name ( @seq_names  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $seq_name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $seq_name ( @seq_names  ) {
	printf "%-40s",  $seq_name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($seqs{$seq_name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($seqs{$seq_name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}

