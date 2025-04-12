#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: msf2fasta.pl <msffile> \n"; 


$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;

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
    $seq_name = $aux[0];
    if ( defined $seqs{$seq_name} ){
	$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;


	

foreach $seq_name ( keys %seqs ) {
    $seqs{$seq_name} =~ s/\-/./g;
    @seq = split ('', $seqs{$seq_name});
    print  ">$seq_name \n";
    $ctr = 0;
    for $i ( 0 .. $#seq ) {
	if ( $seq[$i] !~ '\.' ) {
	    print   $seq[$i];
	    $ctr++;
	    if ( ! ($ctr % 50) ) {
		print  "\n";
	    }

	}
    }
    print  "\n";
}

 


