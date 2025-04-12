#! /usr/bin/perl -w -I/home/i/imihalek/perlscr
use IO::Handle;         #autoflush
# FH -> autoflush(1);

use Simple;		#HTML support

$database = "pubmed";
$rettype = "abstract";
#$rettype = "acc";
$retmode = "html";

$htmlstring  = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi";
$htmlstring .= "?db=$database";
=pod
while ( <> ) {
    chomp;
    @aux = split;
    if (!defined $gi ) {
	$gi = $aux[0];
	$htmlstring .= "&id=$gi";
    } else {
	$gi = $aux[0];
	$htmlstring .= ",$gi";
    }

}

$htmlstring .= "&rettype=$rettype&retmode=$retmode";
print $htmlstring,"\n"; 
=cut

$htmlstring  ="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&term=dihydroorotate+dehydrogenase&retmode=html&rettype=abstract";


$retfile = get $htmlstring || "";
print $retfile;




=pod
    db=nucleotide

Current database values by category:

    Sequence databases:

        genome
        nucleotide
        protein
        popset
        snp
        sequences - Composite name including nucleotide, protein, popset and genome.


Type descriptions:
native 	Default format for viewing sequences.
fasta 	FASTA view of a sequence.
gb 	GenBank view for sequences; constructed sequences 
        will be shown as contigs (by pointing to its parts). 
        Valid for nucleotides.
gbwithparts 	GenBank view for sequences, 
          the sequence will always be shown. Valid for Nucleotides
est 	EST Report. Valid for sequences from dbEST database.
gss 	GSS Report. Valid for sequences from dbGSS database.
gp 	GenPept view. Valid for Proteins.
seqid 	To convert list of gis into list of seqids.
acc 	To convert list of gis into list of accessions. 
chr 	SNP Chromosome Report. 
flt 	SNP Flat File report. 
rsr 	SNP RS Cluster report. 
brief 	SNP ID list. 
docset 	SNP RS summary. 

Not all Retrieval Modes are possible with all Retrieval Types.

Sequence Options:
 
	native 	fasta 	gb 	gbwithparts 	est 	gss 	gp 	seqid 	acc
xml 	x 	x* 	x* 	TBI 	 	TBI 	TBI 	x* 	TBI 	TBI
text 	x 	x 	x* 	x*  		x* 	x* 	x* 	x 	x
html 	x 	x 	x* 	x*  		x* 	x* 	x* 	x 	x
asn.1 	x 	n/a 	n/a 	n/a  		n/a 	n/a 	n/a 	x 	n/a

x = retrieval mode available
*  - existence of the mode depends on gi type
TBI - to be implemented (not yet available)
n/a - not available



=cut
