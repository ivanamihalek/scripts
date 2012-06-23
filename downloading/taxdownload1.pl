#! /usr/gnu/bin/perl -w
# Ivana, Mar 2002
# 1) translate GenBank ID (gi) into Taxonomy ID (using table)
# 2) download tax info from the ncbi server based on taxonomy id

# needs some libs; usage : perl -I/home/protean2/LSETtools/utils  taxdownload.pl

$transl_table_path = "/home/protean5/imihalek/ppint/gi_taxid_prot.dmp";

defined $ARGV[0] ||
    die "usage:  perl -I/home/protean2/LSETtools/utils  taxdownload.pl <gi>";  

use Simple;		#HTML support

$gi = $ARGV[0];
$gi0 = 0;
open ( TRANSLATION_TABLE,"<$transl_table_path") ||
    die "could not open $transl_table_path\n"; 
while ( <TRANSLATION_TABLE> ) {
    ($gi0, $tax_id) = split;
    last if ($gi0 == $gi );
}
($gi0 == $gi) ||
    die "could not locate $gi in $transl_table_path\n";

print "gi: $gi   tax: $tax_id \n"; 

$query_string  =  "http://www.ncbi.nlm.nih.gov/htbin-post/Taxonomy/wgetorg?mode=Info";
$query_string .= "&id=$tax_id";
$query_string .= "&lvl=3&keep=1&srchmode=5&unlock&lin=f";
$tax_info = get $query_string || "";

if ( $tax_info ) {
    #open  (TAXFILE, ">$tax_id.tax") || 
	#die "could not open $tax_id.tax.\n";
    $tax_info =~ /<title>Taxonomy browser \((.*)\)<\/title>/;
    $spec_name= $1;
    while ( $tax_info =~ s/(.*)<(.*)>(.*)/$1$3/g ){};
    $tax_info =~ s/\n//g ;
    if ($tax_info =~/Comments and References/ ) {
	$tax_info =~ s/.*Lineage\( full \)(.*)Comments and References.*/$1/ ;
    } elsif ($tax_info =~/ICTV/)  {
	$tax_info =~ s/.*Lineage\( full \)(.*)ICTV.*/$1/ ;
    } else {
	$tax_info =~ s/.*Lineage\( full \)(.*)Nucleotide.*/$1/ ;
    }
    print "$gi:   $tax_id:     $spec_name:  $tax_info \n";
   # print TAXFILE  $tax_info;
} else {
    print "$tax_id retrieval failure.\n";
}
    
			

