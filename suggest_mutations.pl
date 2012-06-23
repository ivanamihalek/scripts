#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(  defined $ARGV[1] )  
    || die "usage: suggest_mutations.pl <aa> <replacements>.\n";

$ARGV[0] =~ s/\./J/;
$ARGV[1] =~ s/\./J/;

$target_aa = $ARGV[0];
@replacements = split '', $ARGV[1];
$no_replacements =  $#replacements+1;




$ALL_AA = "ACDEFGHIKLMNPQRSTVWYJ";
@all_aa = split '', $ALL_AA;

$SMALL  = "AVGSTCJ";
$MEDIUM = "LPNQDEMIK";
$JUMBO  = "WFYHR";

$HYDROPHOBIC = "LPVAMWFIJ";
$POLAR       = "GTCY";
$NEGATIVE    = "DE";
$POSITIVE    = "KHR";

$AROMATIC    = "WFYH";
$LONG_CHAIN  = "EKRQM";

$OH = "SDETY";
$NH2 = "NQRK";

@properties = ($SMALL , $MEDIUM, $JUMBO, 
	       $HYDROPHOBIC, $POLAR, 
               $NEGATIVE, $POSITIVE, 
	       $AROMATIC, $LONG_CHAIN, 
	       $OH, $NH2);

for $ctr (0 .. $#properties) {
    $target_aa_property[$ctr] = 0;
    foreach $aa ( @all_aa ) {
	$aa_property{$aa}[$ctr] = 0;
    }
    $replacement_property[$ctr] = 0;
}

for $ctr (0 .. $#properties) {
    if ( $properties[$ctr] =~ $target_aa ) {
	$target_aa_property[$ctr] = 1;
    } 
    for $replacement ( @replacements ) {
	if ( $properties[$ctr] =~ $replacement ) {
	    $replacement_property[$ctr] ++;
	} 
    }
    foreach $aa ( @all_aa ) {
	if ( $properties[$ctr] =~ $aa ) {
	    $aa_property{$aa}[$ctr] = 1;
	}
    }
}

for $ctr (0 .. $#properties) {
    $replacement_property[$ctr] /= $no_replacements;
}
=pod
print "     aa: $target_aa  ";
for $ctr (0 .. $#properties) {
    printf  "%4d ", $target_aa_property[$ctr];
}
print " \n";


print "  replacements "; 
for $ctr (0 .. $#properties) {
    printf  "%4.2f ", $replacement_property[$ctr];
}
print " \n";
=cut


foreach $aa ( @all_aa ) {
    $score{$aa} = 0.0;
    for $ctr (0 .. $#properties) {
	$score{$aa} += abs ( $aa_property{$aa}[$ctr] - $target_aa_property[$ctr] );
	$score{$aa} += abs ( $aa_property{$aa}[$ctr] - $replacement_property[$ctr] );
    }
}


@aa_sorted = sort InvHashByValue ( keys(%score)) ;

=pod
foreach $aa ( @aa_sorted) {
    printf "%s   %8.2f\n", $aa, $score{$aa};
}
=cut

 $old_score = -1;
$mut = "";
@mutations = ();
foreach $aa ( @aa_sorted) {
    if ( $score{$aa} != $old_score ) {
	if ( $mut ) {
	    push @mutations, $mut;
	}
	$old_score =  $score{$aa};
	( $aa eq "J")  && ($aa = ".");
	$mut = $aa;
    } else {
	( $aa eq "J")  && ($aa = ".");
	$mut .= $aa;
    }
}
if ( $mut ) {
    push @mutations, $mut;
}
$suggestion = "";
foreach $mut ( @mutations[0 ..3] ) {
    $suggestion .= "($mut)";
}

print "$suggestion\n";


#####################################
sub  InvHashByValue {
    $score{$b} <=> $score{$a};
}
