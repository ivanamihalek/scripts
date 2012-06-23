#! /usr/bin/perl -w
use  DB_File;

( defined $ARGV[1] )  || die "Usage: uniprot_feed.pl <db_name> <flat file>.\n"; 

# initialize th Berkely DB
($dbname, $flatfile) = @ARGV;

%database = ();
($db = tie %database, 'DB_File', $dbname ,  O_CREAT |O_RDWR, 0666)
    || die "cannot open database: $!.\n";

# read flatfile 

open (IF, "<$flatfile") ||
    die "Cno $flatfile: $!.\n";

open (LOG, ">log" ) ||
    die "Cno log: $!.\n";

$entry ="";
$key = "";
$ctr = 0;
while ( <IF> ) {
    next if ( ! /\S/ );
    $entry .= $_;
    if ( /^AC/ ) {
	$_ =~ s/AC//;
	$_ =~ s/\s//g;
	@ids = split ";", $_;
	$key = shift @ids;	    
	print "$key \n";
	foreach $id ( @ids ) {
	    print "\t key$id\n";
	    $database{$id} = "key$key"; # rekeying
	}
    } elsif ( /^\/\// ) {
	print "\t store\n";
	( $key ) ||
	    die "********\n*************\n$entry \n\n no key ??.\n";
	if ( defined  $database{$key} ) {
	    print LOG  "$key defined twice??.\n";
	} else {
	    $database{$key} = $entry;
	}
	$entry = "";
	$key = "";
	$ctr ++;
    }
}
#search in database

#( defined  $database{$key} ) && ( delete  $database{$key} );
#$database{$key} = $value;


#close
close IF;
close LOG;
#untie the databse
undef $db;
untie %database;

print "\n\n\t STORED $ctr ENTRIES.\n\n";
