#! /usr/bin/perl -w
use  DB_File;

( @ARGV > 2 )  || die "Usage: db_store.pl <db_name> <key> <value>.\n"; 

# initialize th Berkely DB
$dbname  = $ARGV[0];
$key = $ARGV[1];
$value = $ARGV[2];

%database = ();
($db = tie %database, 'DB_File', $dbname , O_RDWR, 0666)
    || die "cannot open database: $!.\n";


#search in database

( defined  $database{$key} ) && ( delete  $database{$key} );
$database{$key} = $value;

#untie the databse
undef $db;
untie %database;

