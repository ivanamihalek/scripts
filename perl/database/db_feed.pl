#! /usr/bin/perl -w
use  DB_File;

# initialize th Berkely DB

%database = ();

$db = tie %database, 'DB_File', "test.dat", O_CREAT | O_RDWR, 0666
    || die "Can't initialize database: $!.\n";
$fd = $db->fd();


open DATAFILE, "+<&=$fd"
    || die "Cno datafile: $!.\n";



# fill the database
#$database{'blub'} = "yaddayadda";
#$database{'glub'} = "adday";
$database{'arnie'} = "sally";
delete $database{'glub'};

#untie the databse
undef $db;
untie %database;

close DATAFILE;
