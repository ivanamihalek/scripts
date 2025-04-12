#! /usr/bin/perl -w
use strict;
sub species(@);
(defined $ARGV[0]) || die "Usage: species.pl <descr file>.\n";

my $no_spec;

($no_spec) = split " ", `wc -l  $ARGV[0]`;

$no_spec /= 3;
#print "$no_spec\n";

print species($ARGV[0], $no_spec);

#######################################################################
sub percent (@) {
    my $frac = $_[0];
    my $total =  $_[1];
    if ( ! $total ) {
	return " 0";
    } elsif ( $frac==$total) {
	return " 100";
    } elsif (  $frac/$total < 0.01) {
	return " \$<\$1";
    } else {
 	return sprintf "%5d", int ( 100*$frac/$total);
   }
}
#######################################################################################
# species breakdown
sub species(@) {
    my  ($descr_file, $no_seqs) = @_;
    my $spec_descr_string = "";
    my ($taxon, %count, %adjective, @kingdoms );
    my ($last_taxon, $phylum, $first, $perc, $sum, $sub_first);
    
    %count = ();%adjective = (); @kingdoms = ();

    foreach $taxon  ( "eukaryota", "bacteria", "prokaryota", "archaea", "vertebrata", "arthropoda", "fungi", "plantae", "viruses" ) {
	$count{$taxon} = `grep -i $taxon  $descr_file | wc -l`;  
	chomp  $count{$taxon};
    }
    $count{"prokaryota"} += $count{"bacteria"};

    %adjective = ( "eukaryota", "eukaryotic", "prokaryota", "prokaryotic", "archaea", "archaean", "bacteria", "bacterial", 
		   "vertebrata", "vertebrate", "arthropoda", "arthropodal", "fungi",  "fungal", "plantae",  "plant", "viruses", "viral" );
    $spec_descr_string .= "The alignment consists of ";

    @kingdoms = ();
    foreach $taxon  ( "eukaryota", "prokaryota", "archaea", "viruses" ) {
	next if ( !$count{$taxon});
	push @kingdoms, $taxon;
    }

    $last_taxon = $kingdoms[$#kingdoms];
    $first = 1;
    foreach $taxon  ( @kingdoms ) { # turn this into make_list function
	next if (  $count{$taxon} == 0 );
	if ( $first) {
	    $first = 0;
	} else {
	    $spec_descr_string .= ", ";
	    ($taxon  eq $last_taxon) &&  ($spec_descr_string .= "and");
	}
	$perc = percent ($count{$taxon}, $no_seqs);
	$spec_descr_string .= " $perc"."\\% ".$adjective{$taxon};
	if ( $taxon eq "eukaryota" ) {
	    $sum = 0;
	    foreach $phylum  ( "vertebrata", "arthropoda", "fungi", "plantae" ) {
		$sum += $count{$phylum};
	    }
	    if ( $sum ) {
		$sub_first = 1;
		$spec_descr_string .= " (";
		foreach $phylum  ( "vertebrata", "arthropoda", "fungi", "plantae" ) {
		    next if (  $count{$phylum} == 0 );
		    ( $sub_first ) || ( $spec_descr_string .= ",");
		    ( $sub_first ) &&  ($sub_first = 0);
		    $perc = percent ($count{$phylum}, $no_seqs);
		    $spec_descr_string .= " $perc"."\\% $phylum";
		}
		$spec_descr_string .= ")";
	    }
	}
    }   
    $spec_descr_string .= " sequences.\n";
    $sum = 0;
    foreach $taxon  ( "eukaryota", "prokaryota", "archaea", "viruses" ) {
	$sum += $count{$taxon};
    }
    ( $sum == $no_seqs )  ||  ($spec_descr_string .= " (Descriptions of some sequences were not readily available.)\n");

    return $spec_descr_string;

}

