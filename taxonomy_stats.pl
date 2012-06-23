#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$ctr = 0;
undef $/;
$_ = <>;
$/ = "\n";
@names_for_hypo = ( "hypothetical", "probable", "putative", "-like", "predicted", "homolog", "related");

#@keywords = ( "Eukaryot", "Firmicutes", "Actinobacteria", "Chlamidiae", "Chloroflexi",
#	      "alphaproteobacteria", "betaproteobacteria", "gammaproteobacteria", "deltaproteobacteria", "epsilonproteobacteria");
@keywords = ( "Archaea", 
	      "Firmicutes", "Actinobacteria", "Chlamidiae", "Chloroflexi",
	      "Cyanobacteria", "Chlorobi", "Planctomycetes", "Deinococcus", "Spirochaetes",
	      "Alphaproteobacteria", "Betaproteobacteria", "Gammaproteobacteria", "Deltaproteobacteria", "Epsilonproteobacteria",
	      "Bacteria",
	      "Rodentia", "Canis", "Oryctolagus",  "Homo", "Primates",  
	      "Mammalia",
	       "Amphibia",  "Aves", "Teleostomi",
	      "Plasmodium", "Nematoda", "Dictyostelium", "Euglenozoa", "Alveolata",
	      "Fungi", "Insecta", "Chondrichthyes", "Viridiplantae",
	      "Chordata", "Metazoa", "Eukaryota", 
	      "Viruses");
foreach $kwd ( @keywords ) {
    $kwd_ctr{$kwd} = 0;
}

$tot = $other = 0;
$hypo = 0;
@lines = split '\n';
for ($ctr=0; $ctr < @lines; $ctr+=3  ) {
    if ( $lines[$ctr+1] =~ /\S / ) {
	foreach $hypo_name ( @names_for_hypo) {

	    if ( $lines[$ctr+1] =~ /$hypo_name/i ) {
		$hypo++;
		last;
	    }
	}
    }
    $tot ++;
    $found = 0;
    foreach $kwd ( @keywords ) {
	if ( $lines[$ctr+2]  &&  $lines[$ctr+2] =~ /\S/  &&  $lines[$ctr+2] =~ /$kwd/i  ) {
	    $kwd_ctr{$kwd} ++;;
	    $found = 1;
	    last;
	}
    }
    if (! $found ){
	$other ++;
	(  $lines[$ctr+2] &&  $lines[$ctr+2] =~ /\S/ ) &&	print $lines[$ctr+2], "\n";
    }
}


printf " total: $tot \n";
foreach $kwd ( @keywords ) {
    ($kwd_ctr{$kwd}) && printf "%25s  %4d   %4.1f%%\n", $kwd, $kwd_ctr{$kwd} , 100*$kwd_ctr{$kwd}/$tot;
}
 $other && printf "%25s  %4d   %4.1f%%\n", "other", $other, 100*$other/$tot;

printf "\nhypothetical         %4d   %4.1f%%\n", $hypo, 100*$hypo/$tot;;
