#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use  DB_File;
use Simple;		#HTML support

# initialize th Berkely DB
$gi2taxid = "/home/pine/databases/taxonomy/gi_taxid_prot";
%database = ();
$db = tie %database, 'DB_File', $gi2taxid, O_RDWR, 0444
    || die "cannot open database: $!.\n";

$fd = $db->fd();
open DATAFILE, "+<&=$fd"
    ||  die "Cannot open datafile: $!.\n"; 

@roughly = ( " Bacteria ", " Archaea ", " Metazoa ", " Fungi ", " Viridiplantae ", " Alveolata ",
	     " Mycetozoa ");

while ( <> ) {
    @aux = split;
    $gi = $aux[0];
    if ( defined $database{$gi} ) {
	$taxid = $database{$gi};
	$htmlstring  = "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=$taxid";
	$retfile = get $htmlstring || "";

	$retfile =~ s/\<.+?\>/ /g;
	$retfile =~ s/\&gt\;/\>/g;
	@lines = split '\n', $retfile;
	for $ctr (0 .. $#lines) {
	    if ( $lines[$ctr] =~ /Lineage/ ) {
		$line = $lines[$ctr];
		$line =~ s/.+Lineage//g;
		($line =~ /root/ ) && (	$line =~ s/.+root\s*\;*//g);
		if ( $line =~ /archaea/i || $line =~ /bacteria/i
		     || $line =~ /eukaryota/i  || $line =~ /viruses/i  ) {
		   
		} else { 
		    $line = $lines[$ctr+1];
		}
		$found = 0;
		foreach $interesting ( @roughly ) {
		    if ( $line =~ $interesting ) {
			if ( $interesting eq " Bacteria ") {
			    @lineage = split ';', $line;
			    print "$gi  @lineage[1..3]    \n";
			} else {
			    print "$gi $interesting \n";
			}
			$found = 1;
			last;
		    }
		}
		( $found ) || 	print "$gi  $line\n";
		last;
	    }
	}
	
    } else {
	print "value for the key $gi  not defined.\n";
    }
}


#untie the databse 
undef $db;
untie %database;

close DATAFILE;
