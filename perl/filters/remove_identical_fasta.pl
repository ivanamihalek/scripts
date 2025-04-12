#! /usr/gnu/bin/perl -w  


defined $ARGV[0]  ||
    die "Usage: remove_identical_fasta.pl <fasta_name>  \n"; 

sub process_seq();

$home = `pwd`;
chomp $home;
$name = $ARGV[0] ;

open ( LOG, ">$name.pruning.log" ) ||
    die "Could not open $name.pruning.log:  $!\n";
	
open ( FASTA, "<$name.fasta" ) ||
    die "Could not open $name.fasta:  $!\n";
	
open ( NEW_FASTA, ">$name.new.fasta" ) ||
    die "Could not open $name.new.fasta:  $!\n";
	

$seq = "";
$name = "";
while ( <FASTA>) {

    if (/^>/ ) {
	process_seq();
	$seq = "";
	chomp;
	/\>(.+)/;
	$name = $1;
   } else {
	$seq .= $_;
    }
}
process_seq();



sub process_seq () {

    if ( $seq ) {
	if (  defined $found{$seq} ) {
	    $new_name = "";
	} elsif (  defined  $seen {$name}) {
	    print "$seen{$name} \n";
	    if  ( $seen{$name} =~ /(.+?)\_(\d+)/ ) {
		$number = $2+1;
		$new_name = $1."_$number";
	    } else {
		$new_name .= "_2"
	    }
	} else {
	    $new_name = $name;
	}
	if ( $new_name ) {
	    $found{$seq} = $new_name;
	    $seen{$name} = $new_name;
	    print NEW_FASTA  "> $new_name\n";
	    print NEW_FASTA $seq;
	}
    }
}
