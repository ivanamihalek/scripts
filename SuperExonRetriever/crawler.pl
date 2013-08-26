#! /usr/bin/perl


$fastadir = "/mnt/ensembl/release-67/fasta/";


chdir $fastadir;

@animals = split "\n", `ls -d *_*`;



foreach $animal (@animals) {

    

    chdir $fastadir;
    chdir $animal;

    chdir "dna";
    @fastafiles = split "\n", `ls *.dna.*.fa`;


    (@fastafiles > 2) && next;


    @lines = split "\n",  `ls -l *.dna.*.fa`;
    $ctr = 0;
    foreach $line (@lines) {
	@aux = split " ", $line;
	$size[$ctr] = $aux[4];
	$ctr ++;
    }

    if ( $size[0] !=  $size[1]) {
	print "$animal:  $size[0]  $size[1]\n";
    }

}
