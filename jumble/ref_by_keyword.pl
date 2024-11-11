#! /usr/bin/perl -w
use strict;
sub process_record (@);
sub check_record (@);

defined $ARGV[1] ||
    die "Usage: ref_by_keywod.pl <isi file> <keyword>.\n";

my ($isifile, $kwd) = @ARGV;

my  ($key, $value);
my $reading;
my %field = ();
my %found = ();

open (IF, "<$isifile") || die "Cno $isifile: $!.\n";

while ( <IF> ) {
   
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

close IF;

print "\n";


########################################
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
    ( ! $field{"AB"} ) && return;

    $field{"AB"} =~ s/\s//g;
    $field{"AB"} = lc $field{"AB"};
    if ( $field{"AB"} =~ $kwd ) {
	print "$id, ";
    }

 }
