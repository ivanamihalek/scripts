#! /usr/bin/perl -w

sub process(@_);


@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

($gene, $transcript, $protein,  $from, $to, $exon) = ();
$prev_gene = "";
    %exons = ();

while ( <IF> ) {
    next if ( /Ensembl/);
    next if ( !/\S/);
    chomp;
    ($gene, $transcript, $protein, $from, $to, $exon) = split "\t";

    ( $protein =~ /\S/) || next;

    if ( $prev_gene &&  ($prev_gene ne  $gene) ) {
	process ($prev_gene);
	%exons   = ();
	%protein = ();
    }

    (defined $exons{$transcript}) ||  ( @{$exons{$transcript}} = ());

    push @{$exons{$transcript}}, "$from $to";
    $protein{$transcript} = $protein;

    $prev_gene = $gene;
}

process ($prev_gene);

close IF;



sub process(@_) {

    
    my $gene = $_[0];
    my $longest = 0;
    my $longest_transcript = "";

    foreach my $transcript ( keys %exons ) {

       my $length = 0;
       my $number_of_exons = scalar @{$exons{$transcript}};

       foreach my  $exon_range (@{$exons{$transcript}}) {

	   my ($from, $to) = split " ", $exon_range;
	   $length += abs ($to - $from + 1);
	   #if ($gene eq "ENSG00000204246") {
	    #   print " >>>> $transcript  $protein{$transcript}    $from, $to   $length  \n";
	   #}

       }

       if ( $length > $longest) {
	   $longest = $length;
	   $longest_transcript  = "$protein{$transcript}  $number_of_exons  $length";
       }
    }
    #if ($gene eq "ENSG00000204246") {
#	exit;
    #}

   $longest_transcript || die "longest transcript info failed for $gene\n";
   print "$longest_transcript   $gene  ".  (join "  ", keys %exons) ."\n";

   return;
 
}
