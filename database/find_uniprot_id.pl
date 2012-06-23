#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use  DB_File;
use IO::Handle;         #autoflush
# FH -> autoflush(1);
use Simple;		#HTML support

# download descriptors for varioius ID'd -like what one gets from hssp
# (try to guess where they belong)

# nonredundatnt
$nr = "/home/pine/databases/nr";
$fastacmd = "/home/i/imihalek/bin/blast/fastacmd";


%id_database = ();

$id_db = tie %id_database, 'DB_File', "/home/pine/databases/var2uniprot", O_RDWR, 0444
    || die "Can't initialize database: $!.\n";



while ( <> ) {
    next if ( ! /\S/ );
    chomp;
    @aux = split;
    $id = $aux[0];
    $descr = "";
    $animal = "";
    undef  $transl_id ;
    $transl_id = $id_database{$id};
    ( ((length $id) == 5)  && ! defined  ( $transl_id ) ) && ( $transl_id = $id_database{ $id}); # try pdb translation with chain ID
    ( ((length $id) == 5)  && ! defined  ( $transl_id ) ) && ( $transl_id = $id_database{ substr ($id, 0, 4)}); # try pdb translation
    if ( ! defined  ( $transl_id ) && (length $id) > 6 && $id =~ /_/ ) {
	@aux = split '_', $id;
	$id = $aux[0];
    } 
    if ( ((length $id) == 6  &&  $id =~ /^[A-Z]/) || defined ( $transl_id ) ) {
	# guess swissprot
	if  ( defined $transl_id) {
	    print " $id   $transl_id \n";
	} else {
	    print " $id   $id \n";
	}
    } else { 
	    print " $id   not found\n";
    }
} 





undef $id_db;
untie %id_database;

