#! /usr/bin/perl -w -I/home/ivanam/perlscr
use  DB_File;
use IO::Handle;         #autoflush
# FH -> autoflush(1);
use Simple;		#HTML support

# download descriptors for varioius ID'd -like what one gets from hssp
# (try to guess where they belong)

# nonredundatnt
#$nr = "/home/ivanam/databases/nr/nr";
$nr_descr = "/home/ivanam/databases/nr/nr_descr_BDB";
#$fastacmd = "/home/i/imihalek/bin/blast/fastacmd";

# initialize the database
%database = ();
$db = tie %database, 'DB_File', 
    "/home/pine/databases/uniprot_dbm/uniprot_dbm.dat", O_RDWR, 0444
    || die "cannot open database: $!.\n";

# initialize the database
%nr_database = ();
$nr_db = tie %nr_database, 'DB_File', $nr_descr, O_RDWR, 0444
    || die "cannot open database: $!.\n";






while ( <> ) {
    next if ( ! /\S/ );
    chomp;
    @aux = split;
    $id = $aux[0];
    $descr = "";
    $animal = "";
    print "$id\n";
    ( ((length $id) == 5) 
      && ! defined  ( $transl_id ) ) 
	&& ( $transl_id = $id_database{ $id}); # try pdb translation with chain ID
    ( ((length $id) == 5)  
      && ! defined  ( $transl_id ) ) 
	&& ( $transl_id = $id_database{ substr ($id, 0, 4)}); # try pdb translation
    if ( ! defined  ( $transl_id ) && (length $id) > 6 && $id =~ /_/ ) {
	@aux = split '_', $id;
	$id = $aux[0];
    } 
    if ( ((length $id) == 6  &&  $id =~ /^[A-Z]/) || defined ( $transl_id ) ) {
	# guess swissprot
	if  ( defined $transl_id) {
	    $retval = $database{$transl_id};
	} else {
	    $retval = $database{$id};
	}
	if ( defined $retval ) {
	    @lines = split '\n', $retval;
	    foreach $line ( @lines) {
		if ( $line =~ /^DE/ ) {
		    @aux = split ' ',  $line ;
		    $descr .= " ".join ' ', @aux[1..$#aux]; 
		} elsif ( $line =~ /^OS/ ) {  
		    #@aux = split ' ',  $line ; 
		    #$animal .= " ".join ' ', @aux[1..$#aux]; 
		    #$animal .= "\n\t";
		} elsif ( $line =~ /^OC/ ) {  
		    @aux = split ' ',  $line ; 
		    $animal .= " ".join ' ', @aux[1..$#aux]; 
		}
	    }
	    print "\t$descr\n\t$animal\n"; 
	} else {
	    print "\tnot found.\n\n"; 
	} 

    } else { 
 	#guess genebank 
	$gi = $id;
	if ( $gi =~ /(.+)\-\d/ ) {
	    $gi = $1; #  get gi of -number
	}

	$retval = $nr_database{$gi};
	if ( $retval) {
	    print "\t$retval\n";
	} else {
	    print "not found.\n\n"; 
	}

    }
} 




#untie the databses
undef $db;
untie %database;
undef $nr_db;
untie %nr_database;


