# An example script demonstrating the use of BioMart API.
# This perl API representation is only available for configuration versions >=  0.5 
use strict;
use BioMart::Initializer;
use BioMart::Query;
use BioMart::QueryRunner;

my $confFile = "PATH TO YOUR REGISTRY FILE UNDER biomart-perl/conf/. For Biomart Central Registry navigate to
						http://www.biomart.org/biomart/martservice?type=registry";
#
# NB: change action to 'clean' if you wish to start a fresh configuration  
# and to 'cached' if you want to skip configuration step on subsequent runs from the same registry
#

my $action='cached';
my $initializer = BioMart::Initializer->new('registryFile'=>$confFile, 'action'=>$action);
my $registry = $initializer->getRegistry;

my $query = BioMart::Query->new('registry'=>$registry,'virtualSchemaName'=>'default');

		
$query->setDataset("hsapiens_gene_ensembl");
$query->addFilter("biotype", ["protein_coding"]);

$query->addAttribute("ensembl_gene_id");


if ( $descr_only) {
	$query->addAttribute("description");
} else {

    $query->addAttribute("ensembl_transcript_id");
    $query->addAttribute("ensembl_peptide_id");

    $query->addAttribute("exon_chrom_start");
    $query->addAttribute("exon_chrom_end");
    $query->addAttribute("ensembl_exon_id");
}

$query->formatter("TSV");

my $query_runner = BioMart::QueryRunner->new();

$query_runner->execute($query);
$query_runner->printHeader();
$query_runner->printResults();
$query_runner->printFooter();
#####################################################################
