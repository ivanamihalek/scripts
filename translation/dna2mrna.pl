#! /usr/bin/perl  


use IO::Handle;         #autoflush
# FH -> autoflush(1);

sub initialize_genetic_code;

defined ($ARGV[0] ) || 
    die "Usage: dna2prot.pl <input file>.\n"; 

$if_name = $ARGV[0];


$dna_str = "";
$seqname = "";
open (IF, "<$if_name" ) || die  "Cno $if_name: $!.\n";
while ( <IF> ) {
    if ( /\>/ ) {
	if ( $dna_str ) {
	    process_seq ();
	}
	$dna_str = "";
	/\>\s*(.+)[\s\n]/;
	$seqname = $1;;
	next;
    }
    chomp;
    $aux_str = $_;
    $aux_str =~ s/\s//g;
    $aux_str =~ s/\d//g;
    $dna_str .= $aux_str;
  
}
process_seq ();
close IF;


sub process_seq () {
    @dna_seq = split '', $dna_str;


    $ctr=0;
    print "> $seqname\n";
    foreach $nt  ( @dna_seq ) {
	$ctr++;
	$nt = lc $nt;
	if ( $nt eq "a" ) {
	    $trsl = "u";
	} elsif ($nt eq "c") {
	    $trsl = "g";
	} elsif ($nt eq "t") {
	    $trsl = "a";
	} elsif ($nt eq "g") {
	    $trsl = "c";
	}
	print  $trsl; 
	if ( ! ($ctr %50 ) ) {
	    print "\n";
	}
	
    }
    print "\n";
}





