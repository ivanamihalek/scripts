#!/usr/bin/perl -w 

use strict;

our %sequence;
our %cvg;
our %type;
our %path;
our $home;
our $structure;

sub make_seq_portrait (@){

    my $name = $_[0];
    my @figure_pieces = ();
    my $number_of_residues;
    my ($number_of_chunks, $chunk_size);
    my ($begin, $end, $ctr,$residue,$no_insert_code_residue);
    my ($command, $file,  $file_root, $fh);
    my %numbering_in_qry = ();
    my ($orig_name, $fragment, $frag_begin, $frag_end);

    printf "\t\t seq_portrait\n";

    if ( $name =~/(\w+)\.(\d+)\.(\d+)/ ) { # this name form reserved for fragments
	$fragment   = 1;
	$orig_name = $1;
	$frag_begin = $2;
	$frag_end   = $3;
	$number_of_residues = $frag_end - $frag_begin +1;
    } else {
	$orig_name = $name;
	$fragment = 0;
	$frag_begin = 1;
	$number_of_residues = length $sequence{$name}; 
	$frag_end  = $number_of_residues;
    }
    $number_of_chunks = int ($number_of_residues/500) + 1;
    if (  $number_of_residues > 500 && ($number_of_residues % 500) > 200 ) {
	$number_of_chunks  +=  1;
    }
    $chunk_size =  int ($number_of_residues/$number_of_chunks);



    ( -e "tmp" ) && `rm -rf tmp`; 
    $fh = outopen("tmp");
    foreach $residue ( sort {$a<=>$b} keys %{$cvg{$name}}) {
	$no_insert_code_residue = $residue;
	if ( $structure ) {
	    if ( $residue =~ /[A-Z]/ ){
		$no_insert_code_residue =~ s/[A-Z]//g;
	    }
	} elsif ($fragment) {
	    $no_insert_code_residue = $residue + $frag_begin - 1;
	}
	
	print $fh  " $cvg{$name}{$residue}   $type{$name}{$residue}  $no_insert_code_residue\n"; 
    }
    $fh->close;
    

    $ctr = 0;
    foreach $residue ( sort {$a<=>$b} keys %{$cvg{$name}}) {
	$ctr++;
	$no_insert_code_residue = $residue;
	if ( $residue =~ /[A-Z]/ ){
	    $no_insert_code_residue =~ s/[A-Z]//g;
	}
	$numbering_in_qry{$ctr} = $no_insert_code_residue;

    }


    $begin = 1;
    $end   = $chunk_size;

    for $ctr ( 1 .. $number_of_chunks ) {

	( $ctr == $number_of_chunks) && ( $end = $frag_begin-1+$number_of_residues);
	if ( $fragment) {
	    my ($b, $e);
	    $b = $begin +  $frag_begin-1;
	    $e = $end   +  $frag_begin-1;
	    $file_root = "$orig_name.$b\_$e";
	} else {
	    $file_root = "$orig_name.$numbering_in_qry{$begin}\_$numbering_in_qry{$end}";
	}
	$file = $file_root.".eps"; 
	push @figure_pieces , $file; 

	if ( ( modification_time ( "$home/texfiles/$file") < modification_time ("$name.ranks_sorted") ) ){ 
	    $command = $path{"seq_painter"}." tmp $file_root  $begin  $end ";
	    ( system $command) && die "Error painting the sequence.";

	    $command = " mv $file  $home/texfiles/$file"; 
	    ( system $command) && die "Error moving $file  to texfiles directory."; 
	}

	$begin += $chunk_size; 
	$end   += $chunk_size;
 
    }

    ( -e "tmp" ) &&`rm tmp`; 
 
    return @figure_pieces;
}


1;
