#! /usr/bin/perl -w
sub process();


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
	process();
	%exons = ();
	%protein = ();
    }

    (defined $exons{$transcript}) ||  ( @{$exons{$transcript}} = ());

    push @{$exons{$transcript}}, "$from $to";
    $protein{$transcript} = $protein;

    $prev_gene = $gene;
}

close IF;



sub process() {

   ( scalar (keys %exons) < 2)  && return;
   
   $longest = 0;
   $longest_info = "";

   foreach $transcript ( keys %exons ) {

       $length = 0;
       $number_of_exons = scalar @{$exons{$transcript}};

       foreach  $exon_range(@{$exons{$transcript}}) {

	   ($from, $to) = split " ", $exon_range;
	   $length += abs ($to - $from + 1);

       }

       if ( $length > $longest) {
	   $longest = $length;
	   #$longest_info =  "$gene    $transcript     $protein{$transcript}    $length \n";
	   $longest_info =  "$protein{$transcript}    $number_of_exons\n";
       }

       if ( `grep $protein{$transcript} prot_output.txt` ) {
	   print "$protein{$transcript}    $number_of_exons\n";
       }
   }
   #print $longest_info;

   return;
 
}
