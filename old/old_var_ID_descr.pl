#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use  DB_File;
use IO::Handle;         #autoflush
# FH -> autoflush(1);
use Simple;		#HTML support

# download descriptors for varioius ID'd -like what one gets from hssp
# (try to guess where they belong)

# initialize the database
%database = ();
$db = tie %database, 'DB_File', "/pine/databases/uniprot_dbm/uniprot_dbm.dat", O_RDWR, 0444
    || die "cannot open database: $!.\n";
$fd = $db->fd();
open DATAFILE, "+<&=$fd"
    ||  die "Cannot open datafile: $!.\n";

while ( <> ) {
    chomp;
    @aux = split;
    $id = $aux[0];
    $descr = "";
    $animal = "";
    print " $id\n";
    if ( (length $id) == 6  &&  $id =~ /^[A-Z]/) {
	$retval = $database{$id};
	if ( defined $retval ) {
	    @lines = split '\n', $retval;
	    foreach $line ( @lines) {
		if ( $line =~ /^DE/ ) {
		    @aux = split ' ',  $line ;
		    $descr .= " ".join ' ', @aux[1..$#aux]; 
		} elsif ( $line =~ /^OS/ ) {  
		    @aux = split ' ',  $line ; 
		    $animal .= " ".join ' ', @aux[1..$#aux]; 
		    $animal .= "\n\t";
		} elsif ( $line =~ /^OC/ ) {  
		    @aux = split ' ',  $line ; 
		    $animal .= " ".join ' ', @aux[1..$#aux]; 

		}
	    }
	    print "\t$descr\n\t$animal\n"; 
	} else {
	    print "not found.\n"; 
	} 

    } else { 
 	#guess genebank 
	if ( $id =~ /(.+)\-\d/ ) {
	    $id = $1; #  get rid of -number
	}
	$searchstr =  "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=protein&term=$id";
	$retval = get $searchstr  || "";
	if ( $retval ) {
	    if ( $retval =~ /No items found/ ) {
		print "not found.\n"; 
		next;
	    }
	    $retval =~ s/\n//g;
	    $retval =~ /\<Id\>(.+)\<\/Id\>/;
	    $gi = $1;
	    $searchstr =  "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi";
	    $searchstr .=  "?db=protein&id=$gi";
	    $searchstr .=  "&retmode=text&rettype=native";
	    #print "$searchstr\n\n";
	    $retval = get $searchstr  || "";
	    if ( $retval ) {
		$retval =~ s/\n//g;
		$retval =~ /\<Item Name=\"Title\" Type=\"String\"\>(.+?)\<\/Item\>/;
		if ( defined $1 ) {
		    $aux = $1;
		    $aux  =~ /(.+)\[(.+?)\]/;
		    if ( defined $1 ) {
			$descr = $1;
		    }
		    
		    if ( defined $2 ) {
			$animal = $2;
		    }
		    
		}
		print "\t$descr\n\t$animal\n\n"; 
	    }else {
		print "not found.\n"; 
	    }
	}
	#exit;
   }
}




#untie the databse
undef $db;
untie %database;

close DATAFILE;
