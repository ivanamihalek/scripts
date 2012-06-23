#! /usr/bin/perl -w
use  DB_File;

( @ARGV > 1 )  || die "Usage: db_retrieve.pl <db_name> <key>.\n"; 

# initialize th Berkely DB
$dbname  = $ARGV[0];

%database = ();
($db = tie %database, 'DB_File', $dbname )
    || die "cannot open database: $!.\n";


#search in database
$key = $ARGV[1];
$ret = $database{$key};
if ( defined $ret ) {
    print "$key\n\n$ret\n";
} else {
    print "$key not found in $dbname\n";
}



#untie the databse
undef $db;
untie %database;

