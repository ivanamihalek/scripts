#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use  DB_File;
use IO::Handle;         #autoflush
# FH -> autoflush(1);
use Simple;		#HTML support

# download descriptors for varioius ID'd -like what one gets from hssp
# (try to guess where they belong)

# initialize the database
%database = ();
$db = tie %database, 'DB_File', "/pine/databases/uniprot_dbm/uniprot_dbm.dat", O_RD, 0444
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

    $retval = $database{$id};
    if ( defined $retval ) {
	print $rteval;
	exit;
	@lines = split '\n', $retval;
	foreach $line ( @lines) {
	    if ( $line =~ /^DE/ ) {
		@aux = split ' ',  $line ;
		$descr .= " ".join ' ', @aux[1..$#aux]; 
	    } elsif ( $line =~ /^OC/ ) {  
		@aux = split ' ',  $line ; 
		$animal .= " ".join ' ', @aux[1..$#aux]; 

	    }
	}
	    print "\t$descr\n\t$animal\n"; 
    } else {
	print "not found.\n"; 
    } 

}




#untie the databse
undef $db;
untie %database;

close DATAFILE;
