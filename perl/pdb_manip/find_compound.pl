#!/usr/bin/perl -w  
( @ARGV) || die "Usage: $0  <pdbfile>.\n";


$pdfile = $ARGV[0];  
$PDBFILES = "path to pdbfiles"; 

if ( ! open ( INFILE, "<$PDBFILES/$file_name") ) {
    $file_name = lc $file_name;
    open ( INFILE, "<$PDBFILES/$file_name") ||
	die "cannot open $PDBFILES/$file_name file." ;
}


while ( <INFILE> ) {
    #print "$. $letter_code{'PRO'}\n";
    next if ( ! /\S/ );
    # check for nonprintable characters:
    $record_name = substr $_, 0, 6;
    if ( length $_ > 6 ) {
	$continuation = substr $_, 8, 2;  $continuation  =~ s/\s//g;
    } else {
	$continuation = "";
    }
    $ser_num = $continuation; # same columns, different field
    if ( $record_name =~  /^HEADER/ ) {
	$pdbname = lc substr $_, 62, 4;
	#$pdb_date = substr $_, 50, 9;
    } elsif ( $record_name =~  /^TITLE/) {
	$cont = ($continuation && $continuation>1) ;
	($cont) ||  ($title  =  substr $_, 10, 60);
	($cont) &&  ($title .=  substr $_, 10, 60);
    } elsif ( $record_name =~  /^COMPND/) {
	$cont = ($continuation && $continuation>1) ;
	($cont) ||  ($compound  =  substr $_, 10);
	($cont) &&  ($compound .=  substr $_, 10);
    } 
}

print "$compound \n"; # processs into < pdbChain>  <compnd_string>
