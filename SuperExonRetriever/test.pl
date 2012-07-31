#! /usr/bin/perl

use lib "/home/ivanam/Downloads/ensembl-api/ensembl/modules/";

use strict;
use Bio::EnsEMBL::Registry;
use Getopt::Long;
use Bio::SeqIO;


(@ARGV) || die "Usage: $0  <gene id>\n";

# initialize some defaults
my $species = 'homo_sapiens';
my $source  = 'core'; # core or vega
# allow identifier being passed as the first argument in the command line or by an option -n or -gene_symbol
my $identifier = shift;
GetOptions(
           "n|gene_symbol=s" => \$identifier,
           "species=s"       => \$species,
           "source=s"         => \$source,
          );
 
my $out_seq = Bio::SeqIO->new(
                              -fg => \*STDOUT,
                              -format => 'fasta',
                             );
 
# The current way for accesing ensemble is using the registry
# it matches your API with its corresponding ensembl database version
# Also takes care of the mysql port (now is in a non standard port 5306)
my $reg = 'Bio::EnsEMBL::Registry';
 
$reg->load_registry_from_db(-host => 'ensembldb.ensembl.org', -user=>'anonymous');
 
my $gene_adaptor   = $reg->get_adaptor($species, $source, 'Gene' );
 
foreach my $gene (@{$gene_adaptor->fetch_all_by_external_name($identifier)}) {
 
    # the seq method in gene returns the nucleotide sequence
    # [warning] in transcript and exon objects, the seq method returns a biperl Bio::Seq object
    print "gene sequence for " . $identifier.":\n". $gene->seq() . "\n";
 
    foreach my $trans (@{$gene->get_all_Transcripts}) {
 
        # print the spliced sequence in fasta (you can print the raw seq with $trans->seq->seq())
        print "\ttranscript " . $trans->stable_id() . ":\n";
        $out_seq->write_seq($trans->seq);

	exit;
    }
}
