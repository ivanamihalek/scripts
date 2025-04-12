#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

# if fasta already aligned, convert to msf

defined $ARGV[0]  ||
    die "Usage: afa2msf.pl  <afa_file>.\n"; 

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


print "var alignment = [ \n";
$first = 1;
foreach $name (@names) {
    if ($first) {
	$first = 0;
    } else {
	print ",\n";
    }
    print "{\"name\": \"$name\", \n";
    print "\"sequence\": \"$sequence{$name}\"}";
    
}

print "\n];\n";
