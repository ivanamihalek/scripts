#! /usr/bin/perl -w


sub formatted_sequence ( @);


$dicty ="/home/ivanam/databases/dicty/dicty";
$human ="/home/ivanam/databases/human/human";

$blast = "/home/ivanam/downloads/blast-2.2.16/bin/blastall -p blastp";
$seq_retrieve = "/home/ivanam/downloads/blast-2.2.16/bin/fastacmd";

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: $0  <fasta_file>.\n"; 

$fasta =  $ARGV[0]; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {
    next if ( !/\S/);
    chomp;
    if (/^>\s*(.+)/ ) {
	$name = $1;
	push @names,$name;
	$sequence{$name} = "";
    } else  {
	s/\./\-/g;
	s/\#/\-/g;
	s/\s//g;
	#s/x/\./gi;
	$sequence{$name} .= $_;
    } 
}
close FASTA;



foreach $name ( keys %sequence ) {
    
    print "$name ...";

    open ( TMP, ">tmp.fasta") ||
	die "CNo tmp.fasta: $!\n";

    print TMP ">$name\n";
    print TMP formatted_sequence($sequence{$name});
    print TMP "\n";

    close TMP;

    # find itself in the dicty genome
    $cmd = "$blast -i tmp.fasta -d $dicty -o dicty.blastp -e 1.e-10 -m 8";
    (system $cmd) && die "Error running $cmd\n";

    $ret = `grep $name dicty.blastp | head -n1`;
    chomp $ret;
    @field  = split " ", $ret;
    die "Cannot find itself\n" if ($field[2] ne "100.00");
    
    print " is $field[1]\n";

    $dicty_db_name = $field[1];


    # find homologues  in the human  genome
    
    $cmd = "$blast -i tmp.fasta -d $human -o human.blastp -e 1.e-5 -m 8";
    (system $cmd) && die "Error running $cmd\n";
    
    foreach $line ( split "\n", `cat human.blastp`) {
	@field  = split " ", $line;
	$human_homologue = $field[1];
	`echo  $field[1] > name`;
	$cmd = "$seq_retrieve -d $human -i name -o tmp.fasta";
	(system $cmd) && die "Error running $cmd\n";

	# mutual best hit in dicty:
	$cmd = "$blast -i tmp.fasta -d $dicty -o dicty.blastp -e 1.e-5 -m 8";
	(system $cmd) && die "Error running $cmd\n";

	$ret = `grep $human_homologue dicty.blastp | head -n1`;
	next if ( !$ret);
	chomp $ret;
	@field  = split " ", $ret;
	if ( $field[1] eq $dicty_db_name ) {
	    print "  $dicty_db_name  and $human_homologue are mutual\n";
	}
	
  }
   
}
######################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || 
	die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 
