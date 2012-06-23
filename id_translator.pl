#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use IO::Handle;         #autoflush
# FH -> autoflush(1);
use Simple;		#HTML support

# translate id's to given databse format (if possible)
# for now just produce UniProt id

# too often I cannot find link from NCBI to swissprot

sub get_from_NCBI;

while ( <> ) {
    chomp;
    @aux = split;
    $id = $aux[0];
    if ( $id !~ /\D/ ) {
	print "$id is gi.\n";
	get_from_NCBI ($id);
    } elsif  ( $id =~ /^[A-Z]{2}\_\d{6}/ ) {
	 printf "$id is accession_number (recognized by NCBI}.\n";
	 get_from_NCBI ($id);
    } elsif  ( $id =~ /^[A-Z]{3}\d{4}\.*\d*/ ) {
	printf "$id is EMBI.\n";
    } elsif  (length ($id) == 6 &&  $id !~ "_" ){
	print "$id is UniProt/Swiss-prot.\n"; # recognized by CoDing */
    } else {
	print "$id not recognized.\n";
    }
}


sub get_from_NCBI ( ) {
    my $id = $_[0];
    $htmlstring = "http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&val=$id";
    $retval = get $htmlstring || "";
    if ( $retval) {
	   
	$retval =~ s/\<.+?\>//g;  #strip html
	$swissid = "";
	if ( $retval =~ /\"UniProt\/TrEMBL\:(\w+)\"/ ) {
	    $swissid = $1;
	} elsif ( $retval =~ /\"GeneID\:(\d+)\"/ ) {
	    $geneid = $1;
	    print "GeneID = $geneid.\n";
	    #look for protein links, some of which might be  swissprot
	    $htmlstring = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?";
	    $htmlstring .= "db=gene&cmd=text&dopt=gene_protein&from_uid=$geneid";
	    $retval = get $htmlstring || "";
	    $retval =~ s/\<.+?\>//g;  #strip html
	    @lines = split '\n', $retval;
	    foreach $line ( @lines)  {
		if  ( $line  =~  /\d+\:\s([\w\d]+)/ ) {
		    $candidate = $1;
		    if ( length ($candidate) == 6 &&  $candidate =~ /^[A-Z][\w\d]{5}/ ) {
			$swissid = $candidate;
		    } 
		}
	    }
	}
	if ( $swissid ) {
	    print "SwissProt: $swissid\n";
	} else {
	    print "no link to SwissProt found\n";
	}
    } else {
	print "retrieval of $id from the NCBI site failed.\n";
    }
    print "\n";
}
