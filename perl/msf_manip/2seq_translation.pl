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
	
@names = ();
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
	push @names, $seq_name;
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;


$ctr0 = $ctr1 = 0;
$max_ctr = (length $seqs{$names[0]}) - 1;

for $ctr ( 0 .. $max_ctr  ) {

    $aa0 = substr $seqs{$names[0]}, $ctr, 1;
    $aa1 = substr $seqs{$names[1]}, $ctr, 1;
    ( $aa0 eq '.') || ( $ctr0++);
    ( $aa1 eq '.') || ( $ctr1++);
    printf "%20s   %s   %3d    %s  %3d   %20s \n",
    $names[0], $aa0,  $ctr0, $aa1, $ctr1,  $names[1];
 		      
}
