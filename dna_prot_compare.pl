#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined $ARGV[1]) || die "Usage: dna_prot_compare.pl <dna file>  <prot file> [<translation table no>] [complement (1 or 0)].\n";
($dna, $prot)  = @ARGV[0..1];

print "\n", join " ", @ARGV, "\n";
$table_no = 1;
(defined $ARGV[2] ) && ($table_no=$ARGV[2]);

$complement = 0;
( defined $ARGV[3] ) && ($complement =$ARGV[3] );

sub translate_and_compare;
$dna2prot = "/home/i/imihalek/perlscr/translation/dna2prot.pl";

# read in the original protein
open (IF, "<$prot" ) || die  "Cno $prot: $!.\n";
$orig_protein = "";
while ( <IF> ) {
    next if ( /^>/ );
    $orig_protein .= $_;
}
$orig_protein =~ s/\n//g;
$orig_protein =~ s/\s//g;
close IF;

# read in the orignal dna and shorten it
open (IF, "<$dna" ) || die  "Cno $dna: $!.\n";
$orig_dna = "";
while ( <IF> ) {
    next if ( /^>/ );
    $orig_dna .= $_;
}
$orig_dna =~ s/\n//g;
$orig_dna =~ s/\s//g;
close IF;
if ( $complement ) {
    $orig_dna =~ s/a/b/g;
    $orig_dna =~ s/t/a/g;
    $orig_dna =~ s/b/t/g;

    $orig_dna =~ s/c/d/g;
    $orig_dna =~ s/g/c/g;
    $orig_dna =~ s/d/g/g;
}

translate_and_compare ();

if ( ! $shorter && ! $mismatch) {
    print "nt and translation match.\n";
    exit;
}
   
if ( $mismatch==0 ) {
    print "No mismatch.\n";
} elsif ( $mismatch==1 ) {
    if ( (substr $orig_protein,0, 1) eq "M" ) {
	#print "\n$orig_protein\n\n$translated\n\n";
	if (  (substr $orig_protein,1, $shorter-1)  eq (substr $translated,1, $shorter-1) ) {
	    $new_aa = substr $translated,0, 1;
	    print "Mismatch in the initial M only [$new_aa].\n"; 
	    $mismatch = 0;
	}
    }
} else {
    print "major mismatch.\n";
    exit (-1);
}

if ($shorter) {
    $shortened_dna = substr  $orig_dna, 0, $shorter*3;
}


#output
$dna2 = $dna."cleaned";
open (OF, ">$dna2" ) || die  "Cno $dna2: $!.\n";
@seq = split ('', $shortened_dna);
@aux = split '\.', $dna;
if ( $aux[0] =~  '\/' ) {
    @aux = split '\/', $aux[0];
    $seq_name = $aux[1];
} else {
    $seq_name = $aux[0];
}
print OF "> $seq_name \n";
$ctr = 0;
for $i ( 0 .. $#seq ) {
    if ( $seq[$i] !~ '\.' ) {
	( $seq[$i] =~ '\-' ) && ( $seq[$i] = '.' );
	print OF  $seq[$i];
	$ctr++;
	if ( ! ($ctr % 60) ) {
	    print OF "\n";
	} elsif ( ! ($ctr % 10) ) {
	    print OF " ";
	}

    }
}
print OF "\n";
close OF;

$bkp = $dna.".bkp";
`mv $dna $bkp`;
`mv $dna2 $dna`;
`rm tmp`;

sub translate_and_compare () {

    # translate the dna seq to  aa
    open (OF, ">tmp" ) || die  "Cno tmp: $!.\n";
    print OF $orig_dna;
    close OF;
    $translated = `$dna2prot tmp $table_no`;
    $translated =~ s/\n//g;
    $translated =~ s/\s//g;
    $translated =~ s/\*//g;
    $translated =~ s/>//g;


    # compare
    $len_tr = length $translated;
    # if the last is the asterix chop it off
    if ( substr ($translated, $len_tr-1, 1) =~ '\*' )  {
	$translated = substr ( $translated, 0, $len_tr-1);
	$len_tr --;
    }
    $len_orig = length $orig_protein;


    $shorter = 0;
    if ( $len_tr != $len_orig ) {
	print "diff lengths  \n";
	if ( $len_tr < $len_orig ) {
	    $shorter = $len_tr ;
	} else {
	    $shorter = $len_orig ;
	}
    } else {
	$shorter = $len_tr;
    }

    print " $len_orig    $len_tr \n";
  
    $mismatch = 0;
    for $ctr (0 .. $shorter-1 ) {
	if (  ( substr $orig_protein, $ctr, $shorter-1 -$ctr ) eq  ( substr $translated, $ctr, $shorter-1 -$ctr )  ){
	    #print "mismatch up to  position ", $ctr, "\n";
	    $mismatch = $ctr;
	    last;
	} else {
	}
	   
    }
    
   
}
