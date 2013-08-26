#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";


$taxonomy_file = "/home/ivanam/perlscr/tax_attempt";
$filename = $taxonomy_file;

open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

($spec_short, $ord) = ();
%tax_order = ();

$ctr = 1;
while ( <IF> ) {
    next if ( !/\S/);
    next if ( /\s*#/);
    chomp;
    ($spec_short, $ord) = split;
    $tax_order{$spec_short} = $ctr;
    $ctr++;
}

close IF;


# read in the original fasta

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

while ( <IF> ) {
    chomp;
    if (/^>\s*(.+)/ ) {
	$name = $1;
	if ( ! defined $tax_order{ substr $name, 0, 7} ) {
	    die "Tax_order for $name not found in $taxonomy_file.\n".
		"(The assumed name form is SPC_SPC_GENENAME.)\n";
	}
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

close IF;


# sort the names taxonomically

@names_sorted = sort { $tax_order{substr $a, 0, 7} <=>  $tax_order{substr $b, 0, 7}} @names;



# output in the new order
foreach $seq_name ( @names_sorted  ) {
    $sequence{$seq_name} =~ s/\./-/g;
    @seq = split ('', $sequence{$seq_name});
    print  ">$seq_name \n";
    $ctr = 0;
    for $i ( 0 .. $#seq ) {
	print   $seq[$i];
	$ctr++;
	if ( ! ($ctr % 50) ) {
	    print  "\n";
	}
    }
    print  "\n";
}

