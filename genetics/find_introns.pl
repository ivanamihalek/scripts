#! /usr/bin/perl -w
# find introns from the geneBankk file
# this apparently has some problems - the
# from-to numbers for each exon are sometimes 
# screwed up so we end up wiht a missing residues
# while attempting to shift by one or two positions


( @ARGV ) ||
    die "Usage:  $0  <path to gb file>.\n";
($ctgf) = @ARGV;

sub formatted_sequence ( @);
sub process_main_field (@);
sub process_features_subfield (@);
sub revcom;

$translate = "dna2prot.pl";



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

$buf  = "";
@now_reading = ("");

@isoform = ();
@on_complement = ();
$sequence = "";

$gene_name = "";

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
    if ( $now_reading[0] eq "ORIGIN" ) {
	chomp $line;
	$subseq = substr $line, 10 ;
	$subseq =~ s/\s//g;
	$sequence .=  $subseq ;
	next;
    }
    $key_space = substr  $line, 0, 20;
    ########################################
    if ( $key_space !~ /\S/ ) { # keyspace is empty


	# if I am not reading FEATURES, drop it
	#next if ( $now_reading[0] ne "FEATURES" );

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

    ########################################
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
	    if ( $keyword eq "CDS" ) {
		push @now_reading, "join";
		$buf = substr $line, 21;
	    }
	}

    } 
}



#######################################################
# output exon/intron struct for each isoform
$intron_begin = $intron_end  = 0;

for $isoform_ctr ( 0 .. $#isoform) {
    print "isoform ",  $isoform_ctr+1, "\n";
    $aa_sequence = "";
    $end_pos = 0;
    @exon = split ",", $isoform[$isoform_ctr];
    foreach $nominal_ctr ( 0 .. $#exon ) {

	if ($on_complement[$isoform_ctr]) {
	    $exon_ctr = $#exon - $nominal_ctr;
	} else {
	    $exon_ctr = $nominal_ctr;
	}

	($from, $to) = split  '\.\.', $exon[$exon_ctr];
	if ( $nominal_ctr ) {

	    if ($on_complement[$isoform_ctr]) {
		$intron_begin  = $to;
		# intron end defined in the previous round
		$offset = $intron_begin;
		$length = $intron_end - $offset;

	    } else {
		$intron_end  = $from-1;
		# intron begin defined in the previous round
		$offset = $intron_begin;
		$length = $intron_end - $offset;
	    }

	    $length = $intron_end - $offset;
	    print "intron length $length\n";
	    $intr_length_ctr = 0;
	    do {
		$intr_length_ctr += 1000;
		$aa_sequence .= "x";
	    } while ( $intr_length_ctr < $length );
		
	}

	print "exon ",  $exon_ctr+1;

	# are these  $from $to wrong sometimes?
	print " $from $to  ";
	$offset = $from -1;
	$length = $to - $offset;
	$subseq = substr $sequence, $offset, $length;
	($on_complement[$isoform_ctr]) && ($subseq = revcom $subseq);
	(open OF, ">tmp") || die "cno tmp: $!\n";
	print OF "$subseq\n";
	close OF;
	$transl = `$translate tmp | grep -v \'>\'`;
	    chop $transl;
	    if ( $transl =~ /\*$/ ) {
		chop $transl;
	    } elsif ( $transl =~ /^\*/)  {
		$transl = substr $transl, 1;
	    }

	if ( $transl =~ /\*/ ) {
	    $from --;
	    $to --;
	    $offset = $from -1;
	    $length = $to - $offset;
	    $subseq = substr $sequence, $offset, $length;
	    ($on_complement[$isoform_ctr]) && ($subseq = revcom $subseq);
	    (open OF, ">tmp") || die "cno tmp: $!\n";
	    print OF "$subseq\n";
	    close OF;
	    $transl = `$translate tmp | grep -v \'>\'`;
	    chop $transl;
	    if ( $transl =~ /\*$/ ) {
		chop $transl;
	    } elsif ( $transl =~ /^\*/)  {
		$transl = substr $transl, 1;
	    }

	}

	if ( $transl =~ /\*/ ) {
	    $from +=2;
	    $to   +=2;
	    $offset = $from -1;
	    $length = $to - $offset;
	    $subseq = substr $sequence, $offset, $length;
	    ($on_complement[$isoform_ctr]) && ($subseq = revcom $subseq);
	    (open OF, ">tmp") || die "cno tmp: $!\n";
	    print OF "$subseq\n";
	    close OF;
	    $transl = `$translate tmp | grep -v \'>\'`;
	    chop $transl;
	    if ( $transl =~ /\*$/ ) {
		chop $transl;
	    } elsif ( $transl =~ /^\*/)  {
		$transl = substr $transl, 1;
	    }
	}

	$transl =~ s/[\n\s]//g;
	$end_pos += length ($transl);
	print $transl, "   endpos $end_pos \n";
	$aa_sequence .= $transl;
	if ($on_complement[$isoform_ctr]) {
	    $intron_end   = $from -1;
	} else {
	    $intron_begin = $to+1;
	}
	#exit;
    }
    print "end isoform ",  $isoform_ctr+1, "\n\n";
    push @formatted_seqs, formatted_sequence($aa_sequence);

}

open (OF, ">$gene_name.fasta") ||
    die "Cno $gene_name.fasta";


for $ctr ( 0 .. $#formatted_seqs ) {

    print OF ">$gene_name\_if", $ctr+1, "\n";
    print OF  "$formatted_seqs[$ctr]\n";
}

close OF;


########################################################
########################################################
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
########################################################
sub process_main_field (@) {
    my $keyword = shift @_;
    my $input   = shift @_;
    if ( $keyword eq "ORIGIN" ) {
	print "found sequence\n";
	$sequence = "";
    } 
    return;
}

########################################################
sub process_features_subfield (@) {
    my $input =  shift @_;
     #print " @now_reading  \n"; #$buf\n";
    if ($now_reading[1] eq "gene" && $now_reading[2] eq "gene" ) {
	$input =~ /\=\"(.+?)\"/ ;
	$gene_name = $1;
	print "gene $gene_name\n";

    } elsif ($now_reading[1] eq "CDS" && $now_reading[2] eq "join" ) {

	if ( $input !~ /[\>\<]/) { # to sure what the annotation like
                                   # complement(1..>1059)  is supposed to mean
	    if ( $input =~ /complement/ ) {
		push @on_complement, 1;
		$input =~ s/complement//;
	    } else {
		push @on_complement, 0;
	    }
	    $input =~ s/join//;
	    $input =~ s/[\(\)\n]//g;
	    push @isoform, $input;
	}
    }
}

########################################################
sub rev{

    my($sequence)=@_;

    my $rev=reverse $sequence;   

    return $rev;
}

sub com{

    my($sequence)=@_;

    $sequence=~tr/acgtuACGTU/TGCAATGCAA/;   
 
    return $sequence;
}

sub revcom{

    my($sequence)=@_;

    my $revcom=rev(com($sequence));

    return $revcom;
}

