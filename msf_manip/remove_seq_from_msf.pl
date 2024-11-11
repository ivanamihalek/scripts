#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)

# FH -> autoflush(1);
(@ARGV >= 2) ||
    die "Usage: remove_seq_from_msf.pl <msffile> seq_name_1 [seq_name_2 ...]\n";


$home = `pwd`;
chomp $home;
$msf_name  = shift  @ARGV ;
@skip_names = @ARGV;

open ( MSF, "<$msf_name" ) ||
    die "Cno: $msf_name  $!\n";
	

while ( <MSF>) {
    if ( /^ Name/ ) {
	@aux = split;
	$seq_name = $aux[1];
	if ( ! grep {$_ eq $seq_name} @skip_names ){
	    push @names,$seq_name;
	}
    }
    last if ( /\/\// );
    last if ( /CLUSTAL FORMAT for T-COFFEE/ );
}

while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $sequence{$seq_name} ){
	$sequence{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$sequence{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;
   

$seqlen = length $sequence{$seq_name};
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names  ) {
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name ( @names  ) {
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
