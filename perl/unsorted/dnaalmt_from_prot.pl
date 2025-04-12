#! /usr/bin/perl 

(defined $ARGV[1]) || die "Usage: dnaalmt_from_prot.pl <msf_file> <fasta file>.\n";


use IO::Handle;         #autoflush
# FH -> autoflush(1);

$msf_file     = $ARGV[0];
$fasta_file   = $ARGV[1];
$new_msf_file = $msf_file.".phylip";


# find msf file, read in the sequences
open ( MSF, "<$msf_file" ) ||
    die "Cno $msf_file: $!.\n";
%prot_seq = ();
while (<MSF>) {
    if ( /MSF/ && /Type/ ) {
	@aux = split;
	$prot_length = $aux[1];
    }
    next if ( /PileUp/ ||  /Weight/ || /Check/ || /Len/ || /\/\//);
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $prot_seq{$seq_name} ){
	$prot_seq{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$prot_seq{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}
close MSF;



# find dna fasta file
open ( FASTA, "<$fasta_file" ) ||
    die "Cno $fasta_file: $!.\n";
%dna_seq = ();
while ( <FASTA> ) {
    next if ( ! (/\w/) );
    chomp;
    if ( /^>/ ) {
	$seq_name = $_;
	$seq_name =~ s/[>\s]//g;
    } else {
	$aux = $_;
	$aux =~ s /\s//g;
	if ( defined $dna_seq{$seq_name} ){
	    $dna_seq{$seq_name} .= $aux;
	} else { 
	    $dna_seq{$seq_name}  = $aux;;
	}
    }
    
}
close FASTA;

open ( NEW_MSF, ">$new_msf_file" ) ||
    die "Cno $new_msf_file: $!.\n";
# for each specie,find its dna translation
$noseq = 0;
foreach $seq_name ( keys %prot_seq ) { 
    $dna_ctr{$seq_name} = 0;
    $noseq ++;
}
printf  NEW_MSF " %d   %d \n", $noseq, 3*$prot_length;

$l  = int ( $prot_length/ 18 );
for ( $ctr=0; $ctr<= $l; $ctr ++ ){

    foreach $seq_name ( keys %prot_seq ) {

	if ( !$ctr) {
	    printf  NEW_MSF "%-10s",  "$seq_name";
	}
	if ( $ctr == $l  ) {
	    $upper = length ($prot_seq{$seq_name}) % 18;
	} else {
	    $upper = 18;
	}
	for ( $pos=0; $pos< $upper; $pos ++ ){
	    $aa = substr $prot_seq{$seq_name}, $ctr*18+$pos, 1;
	    if ( $aa =~ '\.' ) {
		printf   NEW_MSF "---";
	    } else {
		$codon = substr $dna_seq{$seq_name},  $dna_ctr{$seq_name},3;
		$dna_ctr{$seq_name} +=3;
		printf   NEW_MSF "%3s", $codon;
	    }
	    if ( ! (($pos+1)% 3) ) {
		print  NEW_MSF  " ";
	    }
	}
	print  NEW_MSF  "\n";
    }
    print  NEW_MSF  "\n";
}

close NEW_MSF;

