#! /usr/bin/perl -w
use  DB_File;

# initialize th Berkely DB

%database = ();
$db = tie %database, 'DB_File', "test.dat", O_RDWR, 0444
    || die "cannot open database: $!.\n";

$fd = $db->fd();
open DATAFILE, "+<&=$fd"
    ||  die "Cannot open datafile: $!.\n";

#dump the database

foreach $key ( keys %database ) {
    print "$key  $database{$key} \n";
}
if ( defined $database{"I dont exist"} ) {
    print $database{"I dont exist"};
} else {
    print "value for the key \"I dont exist\" not defined.\n";
}


#untie the databse
undef $db;
untie %database;

close DATAFILE;
