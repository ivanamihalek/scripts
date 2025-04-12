#! /usr/bin/perl -w
use strict;
sub process_record (@);
sub check_record (@);

my  ($key, $value);
my $reading;
my %field = ();
my %found = ();

while ( <> ) {
   
    next if ( ! /\S/ );
    next if (  /==/ );
    next if (  /^Note/ );
    next if (  /^FN/ ); # says: ISI export format
    chomp;
    $key = substr $_, 0, 2;
    $value = substr $_, 2;
    if ( $key  eq "ER" ) {
	#check_record (%field);
	process_record (%field);
	%field = ();
    } elsif ( $key !~ /\s\s/  ) {
	$reading = $key;
	$field{$key} = $value;
    } else {
	$field{$reading} .= ";".$value;
    }

}

sub check_record ( @) {
    my %field = @_;
    foreach ( "UT", "AU", "TI", "SO", "PY", "VL", "PS" ) {
	if ( ! defined $field{$_} ) {
	    print" \n ======= MISSING $_ !!!! ======== \n";
	    print join "\n", %field;;
	    exit;
	}
    }
}

sub process_record ( @) {
    my %field = @_;
    my $id;
    my ($author, $l, $f, $first, $initials);
    my $first_author;
    
    # article id
    $id = $field{"UT"};
    $id =~ s/MEDLINE\://;
    ( defined $found{$id} ) && return;
    $found{$id} = 1;
    print "\@Article\{ $id,\n";

	# authors 
	print "\t author = \{";
	$first_author = 1;
	foreach $author ( split ";",  $field{"AU"} ){
	    ($l, $f) = split ",", $author;
	    $initials = "";
	    foreach  $first ( split " ", $f) {
		$initials .= " ".(substr $first, 0, 1).".";
	    }
	    if ( $first_author)  { 
		$first_author = 0;
	    } else {
		print  " and ";
	    }
	    print "$l, $initials";
	}
	print "},\n";


	# title
	print "\t title = \{";
	print $field{"TI"};
	print "},\n";
	
	# journal
	print "\t journal = \{";
	print $field{"SO"};
	print "},\n";
	

	#year
	print "\t year = \{";
	print $field{"PY"};
	print "},\n";


	#volume
	print "\t volume = \{";
	print $field{"VL"};
	print "},\n";


	#pages
	print "\t pages = \{";
	print $field{"PS"};
	print "}\n";



	print "}\n";
 }
