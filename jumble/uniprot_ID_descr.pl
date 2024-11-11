#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use  DB_File;


# initialize the database
%database = ();
$db = tie %database, 'DB_File', 
    "/home/ivanam/databases/swissprot/full_dat/swiss.bdb", O_RDWR, 0444
    || die "cannot open database: $!.\n";






while ( <> ) {
    next if ( ! /\S/ );
    chomp;
    @aux = split;
    $id = $aux[0];
    $descr = "";
    $animal = "";
    print "$id\n";
    $retval = $database{$id};

    if ( defined $retval ) {
	if  ( $retval =~ /^key/ ) {
	    $retval =~ s/key//;
	    $id = $retval;
	    $retval = $database{$id};
	} 	
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
	print "\tnot found.\n\n"; 
    } 

} 




#untie the databses
undef $db;
untie %database;

