#! /usr/gnu/bin/perl -w
# Ivana, Mar 2002
# download tax info from the ncbi server based on taxonomy id

# needs some libs; usage : perl -I/home/protean2/LSETtools/utils  taxdownload.pl

defined $ARGV[0] ||
    die "usage:  perl -I/home/protean2/LSETtools/utils  taxdownload.pl <tax_id>";  

use Simple;		#HTML support

$tax_id = $ARGV[0];
$query_string  =  "http://www.ncbi.nlm.nih.gov/htbin-post/Taxonomy/wgetorg?mode=Info";
$query_string .= "&id=$tax_id";
$query_string .= "&lvl=3&keep=1&srchmode=5&unlock&lin=f";
$tax_info = get $query_string || "";
#$tax_info = "Lineage( full )\n Viruses; Retroid viruses; Retroviridae; Lentivirus; Primate lentivirus group ICTV homepage";


if ( $tax_info ) {
    #open  (TAXFILE, ">$tax_id.tax") || 
	#die "could not open $tax_id.tax.\n";
    $tax_info =~ /<title>Taxonomy browser \((.*)\)<\/title>/;
    $spec_name= $1;
    while ( $tax_info =~ s/(.*)<(.*)>(.*)/$1$3/g ){};
    $tax_info =~ s/\n//g ;
    $tax_info =~ s/.*Lineage\( full \)(.*)ICTV.*/$1/ ;
    print "$tax_id:     $spec_name:  $tax_info \n";
   # print TAXFILE  $tax_info;
} else {
    print "$tax_id retrieval failure.\n";
}
    
			

