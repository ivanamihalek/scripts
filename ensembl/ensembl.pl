#!/usr/bin/perl

use Bio::EnsEMBL::Registry;
use Data::Dumper;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org', # alternatively 'useastdb.ensembl.org'
    -user => 'anonymous'
);


#my $gene_adaptor  = $registry->get_adaptor( 'Human', 'Core', 'Gene' );
my $slice_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Slice' );


# Obtain a slice covering the entire chromosome X
#my $slice = $slice_adaptor->fetch_by_region( 'chromosome', 'Y' );

my $stable_id =  'ENSG00000099889';

my $slice = $slice_adaptor->fetch_by_gene_stable_id ($stable_id);

my $genes = $slice->get_all_Genes();
while ( my $gene = shift @{$genes} ) {

    ($gene->stable_id() eq  $stable_id)  || next;
    #print Dumper($gene), "\n";

    my $gstring = feature2string($gene);
    print "$gstring $stable_id \n";


    my $transcripts = $gene->get_all_Transcripts();
    while ( my $transcript = shift @{$transcripts} ) {

        # The protein sequence is obtained from the translate() method. If the
        # transcript is non-coding, undef is returned.
	my $protein = $transcript->translate();
        defined $protein  || next;

        my $tstring = feature2string($transcript);
        print "\t$tstring\n";

        foreach my $exon ( @{ $transcript->get_all_Exons() } ) {
            my $estring = feature2string($exon);
            print "\t\t$estring\n";
        }
	# The spliced_seq() method returns the concatenation of the exon
        # sequences. This is the cDNA of the transcript
	print "cDNA: ", $transcript->spliced_seq(), "\n";

        # The translateable_seq() method returns only the CDS of the transcript
	print "CDS: ", $transcript->translateable_seq(), "\n";

        # UTR sequences are obtained via the five_prime_utr() and
        # three_prime_utr() methods
	my $fiv_utr = $transcript->five_prime_utr();
	my $thr_utr = $transcript->three_prime_utr();

	print "5' UTR: ", ( defined $fiv_utr ? $fiv_utr->seq() : "None" ), "\n";
	print "3' UTR: ", ( defined $thr_utr ? $thr_utr->seq() : "None" ), "\n";


	print "Translation: ", 
	( defined $protein ? $protein->seq() : "None" ), "\n";

    }

}



##########################################
sub feature2string
{
    my $feature = shift;

    my $stable_id  = $feature->stable_id();
    my $seq_region = $feature->slice->seq_region_name();
    my $start      = $feature->start();
    my $end        = $feature->end();
    my $strand     = $feature->strand();

    return sprintf( "%s: %s:   from %d  to %d   (%+d)",
        $stable_id, $seq_region, $start, $end, $strand );
}






