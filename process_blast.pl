#! /usr/bin/perl

sub print_seq (@);

(@ARGV == 2 ) ||
    die "Usage: process_blast.pl <blastp m8 or m9> <fasta file>.\n";

($blastp, $fasta) = @ARGV;

$file= $blastp;
open ( IF, "<$file") ||
    die "Cno $file: $!.\n";
@names = ();
$positives = 0;
while ( <IF> ) {
    next if ( !/\S/);
    if ( /^\#/ ) {
	if ( /positives/ ) {
	    $positives = 1;
	}
	next;
    }
    chomp;
    if ( $positives ) {
	($query_id, $subject_id,  $pct_identity, $pct_positives, 
	 $alignment_length, 
	 $mismatches, $gap_openings, $q_start, $q_end, 
	 $s_start, $s_end, $e_value, $bit_score) = split;
    } else {
	($query_id, $subject_id,  $pct_identity, $alignment_length, 
	 $mismatches, $gap_openings, $q_start, $q_end, 
	 $s_start, $s_end, $e_value, $bit_score) = split;
    }
    if ( $subject_id =~ /\|/ ) {
	@aux = split '\|', $subject_id;
	$subject_id = $aux[1];
    }
    next if ( defined $begin{$subject_id}) ;
    
    push @names, $subject_id;
    $begin{$subject_id} = $s_start;
    $end{$subject_id}   = $s_end;
}

close IF;


$file= $fasta;
open ( IF, "<$file") ||
    die "Cno $file: $!.\n";
 while ( <IF> ) {
    chomp;
    if (/^>\s*(.+)/ ) {

	$name = $1;
	$name =~ s/\s//g;
	$sequence{$name} = "";
    } else  {
	s/\-/\./g;
	s/\#/\./g;
	s/\s//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}

close IF;


foreach $subject (@names) {
    defined $sequence{$subject} ||
	die "$subject not found in $fasta.\n";
    print "> $subject\n";
    $offset = $begin{$subject} - 1;
    $length =   $end{$subject} - $offset;
    print_seq ( substr  $sequence{$subject}, $offset, $length);
    #print " $subject  ", length $sequence{$subject}, 
    #"      $begin{$subject}   $end{$subject}   $offset   $length \n";
}

###########################

sub print_seq (@) {
    my @seq = split ('', $_[0]);
    $ctr = 0;
    foreach $aa ( @seq ) {
	print   $aa;
	$ctr++;
	($ctr % 50) ||   print  "\n";
    }
    print "\n";
    
}
