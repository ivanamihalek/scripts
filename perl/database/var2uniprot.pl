#! /usr/bin/perl -w
use  DB_File;

# initialize th Berkely DB

%database = ();

$db = tie %database, 'DB_File', "/home/pine/databases/var2uniprot", O_RDWR, 0444
    || die "Can't initialize database: $!.\n";
$fd = $db->fd();



open (IF, "</pine/databases/uniprot.id_table" ) || die "Cno uniprot.id_table: $!.\n";
while ( <IF> ) {
    next if ( ! /\S/ );
     # fill the database
    chomp;
    @aux = split;
    $uniprotid = shift @aux;
    for $id ( @aux ) {
	if ( $id ne "-" ) {
	    $database{"$id"} = $uniprotid;
	   #print " $id ---> $uniprotid \n";
	}
    }
}
#untie the databse
undef $db;
untie %database;


close IF;
