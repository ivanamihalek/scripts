#! /usr/bin/perl -w

( @ARGV ) ||
    die "Usage: process_gbs.pl <path to contig file>.\n";
($ctgf) = @ARGV;

sub process_main_field (@);
sub process_features_subfield (@);

@main_fields = ( "LOCUS", "DEFINITION", "ACCESSION",
		"VERSION","KEYWORDS","SOURCE","REFERENCE",
		"COMMENT","FEATURES","ORIGIN","REMARK","PROJECT", "CONTIG");  
foreach $main_field ( @main_fields ) {
    @{$subfields{$main_field}} = ();
}

@{$subfields{"FEATURES"}} = ( "source", "gene", "mRNA", "CDS",
	      "STS", "misc_RNA", "misc_feature",
	       "repeat_region","V_segment", "exon", "3'UTR");

open (IF, "<$ctgf") ||
    die "Cno $ctgf: $!.\n";

$locus_name = "";
$buf  = "";
@now_reading = ("");

while ( <IF> ) {
    next if ( ! /\S/ );
    if (  /^\/\// ) { # the end of record (contig in this case)
	if (@now_reading == 3) {
	    process_features_subfield ($buf);
	    pop @now_reading;
	}
	@now_reading = ("");
	next;
    }
    $line = $_;
    $key_space = substr  $line, 0, 20;
    if ( $key_space !~ /\S/ ) { # keyspace is empty

	# if I am not reading FEATURES, drop it
	next if ( $now_reading[0] ne "FEATURES" );

	$line = substr $line, 21; # get rid of the empty space
	# if I am reading features, check whether I have 
	# a new keyword, or whether it is a continuation
	# of the previous line
	if ( $line =~ /^\// ) { #new keyword
	    if (@now_reading == 3) {
		process_features_subfield ($buf);
		pop @now_reading;
	    }
	    $line =~ /\/(.+?)\=/ || $line =~ /\/(.+)/  ;
	    push @now_reading, $1;
	    $buf = $line;
	} else { #continuation
	    $buf .= $line;
	}

    } else {  #  keyspace is not empty
	if (@now_reading == 3) {
	    process_features_subfield ($buf);
	    pop @now_reading;
	}
	if ( grep {$key_space =~ $_ } @main_fields ) {	
	    ($keyword) = split " ", $key_space;
	    @now_reading = ($keyword);
	    process_main_field ($keyword, $line);

	} elsif ( $now_reading[0] eq "FEATURES" ) {

	    # if I am reading FEATURES, and the keyspace is 
	    # nonempty, I am changing the subfield
	    @now_reading = ("FEATURES");
	    #pop @now_reading;
	    ($keyword) = split " ", $key_space;
	    push @now_reading, $keyword;
	    if ( $keyword eq "mRNA" or $keyword eq "CDS" ) {
		push @now_reading, "join";
		$buf = substr $line, 21;
	    }
	}

    } 


}

########################################################
########################################################
sub process_main_field (@) {
    my $keyword = shift @_;
    my $input =  shift @_;
    if ( $keyword eq "LOCUS" ) {
	@aux = split;
	$locus_name = $aux[1];
    } 
    return;
}
########################################################
sub process_features_subfield (@) {
    my $input =  shift @_;
    print " @now_reading  \n$buf\n";
}
