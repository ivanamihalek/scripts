#! /usr/bin/perl -w
sub formatted_sequence ( @);

(@ARGV > 1) ||
    die "Usage:  $0  <nt seq file>  <sac species> \n";

($seqfile, $spec) = @ARGV;

$genome_dir = "/home/ivanam/databases/fungal_genomes";
$sac_dir = "$genome_dir/$spec";
###
$blastn  = "/home/ivanam/downloads/blast-2.2.16/bin/blastall";
$extract = "/home/ivanam/perlscr/extractions/extr_region_from_seq.pl";
$revcom  = "/home/ivanam/perlscr/translation/revcom.pl";
$translate = "/home/ivanam/perlscr/translation/dna2prot.pl";

#################################################
# the length of the query
$qry_seq = `grep -v \'>\' $seqfile`;

$qry_seq =~ s/[\s\n]//g;
$qry_len = length $qry_seq;


#################################################
# check for the existence/naming of the database
foreach ( $seqfile, $blastn, $sac_dir, $extract, $revcom, $translate) {
    (  -e $_) || die "$_ not found\n";
}

@fasta = split "\n", `ls $sac_dir/*.fasta`;

(!@fasta)   && die "No fasta file found in $sac_dir\n";
(@fasta >1) && die "More than 1  fasta file found in $sac_dir:\n\t".
    (join "\n\t", @fasta)."\n";

@aux = split "/", $fasta[0];
$fasta = pop @aux;


#################################################
# blast

@aux = split '\.', $seqfile;
$outname = shift @aux;
@aux = split '\.', $fasta;
$rootname = lc shift @aux;
$outname .= ".".$rootname; # to be re-used
$outname .= ".blastn";


$cmd = "$blastn -p blastn -i $seqfile -d $sac_dir/$fasta -o $outname -m 8";
(system $cmd) && die "Error running $cmd: $!\n";

$best_hit = `head -n1 $outname`;
print $best_hit;
chomp $best_hit;

($qry, $target, $pct, $len, $mismatch, $gaps, 
 $q_start, $q_end, $s_start, $s_end, $e, $bit) = ();
($qry, $target, $pct, $len, $mismatch, $gaps, 
 $q_start, $q_end, $s_start, $s_end, $e, $bit) = split " ", $best_hit;

( $e < 0.001) || die "no hit (?)\n";
 

$complement = 0;

if ( $s_start>  $s_end) {
    $tmp =  $s_start;
    $s_start = $s_end;
    $s_end = $tmp;
    $complement = 1;
}


( $complement ) && print "coded on compl. strand \n";

#################################################
# extract seq
$from = $s_start - $q_start - 100;
$to   = $s_end   + ($qry_len -  $q_end + 100);

print "extract from $from to $to\n";
$outname = $rootname;
$outname .= ".$target\_$from\_$to";
$cmd = "$extract $sac_dir/$fasta $target $from $to";
if ( $complement ) {
    $cmd  .= " | $revcom ";
    $outname .= ".revcom";
} 
$outname .= ".nt";
$cmd  .= " > $outname";
(system $cmd) && die "Error running $cmd: $!\n";


#################################################
# translate in 3 frames
$all = "";
for $shift ( 0 .. 2) {
    print "\n shift $shift\n";
    $cmd = "$translate $outname shift $shift > tmp";
    (system $cmd) && die "Error running $cmd: $!\n";
    print `cat tmp`;
    print "\n";
    $all .= `grep -v \'>\' tmp`;
}  
(-e "tmp") && `rm tmp`;

$all =~ s/[\s\n]//g;

@seqs = split '\*', $all;

@seqs_sorted = sort { length $b <=> length $a} @seqs;

print formatted_sequence ($seqs_sorted[0]);
print "\n\n";



######################################################
######################################################
######################################################
######################################################
######################################################
######################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || 
	die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 
