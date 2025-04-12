#! /usr/bin/perl -w
use  DB_File;
sub formatted_sequence ( @);

( defined $ARGV[0] )  || die "Usage: fasta_from_uniprot.pl  <name> or <name file>.\n"; 

# initialize th Berkely DB
$dbname  = "/pine/databases/uniprot_dbm/uniprot_dbm.dat";

%database = ();
($db = tie %database, 'DB_File', $dbname )
    || die "cannot open database: $!.\n";

if ( -e $ARGV[0] ) {

    open NAMES, "<$ARGV[0]" || die "Cno $ARGV[0]\n";
    
    #search in database
    while ( <NAMES> ) {
	chomp;
	@aux = split;
	$name = $aux[0];
	$ret = $database{$name};
	if ( defined $ret ) {
	
	    @lines = split "\n", $ret;
	    print "> $name\n";
	    $seq = "";
	    foreach ( @lines ) {
		/^\s\s/ && ($seq .= $_);
	    }
	    $seq =~ s/\s//g;
	    print formatted_sequence ($seq), "\n";

	} else {
	    print "$name not found in $dbname\n";
	}
    }

    close NAMES;
} else {
    $name = $ARGV[0];
    $ret = $database{$name};
    if ( defined $ret ) {
	
	@lines = split "\n", $ret;
	print "> $name\n";
	$seq = "";
	foreach ( @lines ) {
	    /^\s\s/ && ($seq .= $_);
	}
	$seq =~ s/\s//g;
	print formatted_sequence ($seq), "\n";

    } else {
	print "$name not found in $dbname\n";
    }
}

#untie the databse
undef $db;
untie %database;

#########################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 

