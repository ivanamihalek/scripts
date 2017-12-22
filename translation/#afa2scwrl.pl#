#! /usr/bin/perl -w

# if fasta already aligned, convert to msf

defined $ARGV[1]  ||
    die "Usage: $0  <afa_file> <out name root>.\n".
    "Note: in the afa file template should come first, replacement second.\n"; 

($fasta, $name_root) =  @ARGV; 

@names = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";

TOP: while ( <FASTA> ) {
    next if ( !/\S/);
    chomp;
    if (/^>\s*(.+)/ ) {
	$name = $1;
	push @names,$name;
	$seq{$name} = "";
    } else  {
	s/\s//g;
	$seq{$name} .= uc $_;
    } 
}
close FASTA;

( @names == 2 ) || die "2 seqs expected in $fasta.\n";



$template = $seq{$names[0]};
$replacement = $seq{$names[1]};

@templ_arr = grep ( /[\w\-\.]/, (split //, $template) );
@repl_arr  = grep ( /[\w\-\.]/, (split //, $replacement) );


( $#templ_arr ==  $#repl_arr ) ||
    die "Unequal sequence lengths (?!)\n";

$new_seq = "";
@replaced = ();
$new_arr_ctr = 0;
for $i ( 0 .. $#templ_arr ){
    next if ($templ_arr[$i] =~ /[\.\-]/ );
    $new_arr_ctr++;
    if ( $repl_arr[$i] =~ /[\.\-]/ ) {
	$new_seq .= $templ_arr[$i];
    } else {
	$new_seq .= $repl_arr[$i];
	push @replaced, $new_arr_ctr;
    }
}

################
$filename = "$name_root.scwrl";
open (OF, ">$filename" ) || die "Cno $filename.\n";

$ctr = 0;
$max = length $new_seq;
do {
    print OF substr $new_seq, $ctr, 50;
    print OF "\n";
    $ctr += 50;
} while ($ctr <= $max );

close OF;

################
$filename = "$name_root.replaced";
open (OF, ">$filename" ) || die "Cno $filename.\n";

print OF join "+", @replaced;
print OF "\n";

close OF;
