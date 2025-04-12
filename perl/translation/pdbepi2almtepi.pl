#! /usr/bin/perl -w

defined $ARGV[1] ||
    die "Usage: pdbepi2almtepi.pl <pdblist>  <ranksfile>\n";

$epifile = $ARGV[0];
if ( ! -e  $epifile ) {
    print "$pwd/$epifile missing\n";
    next;
} 
$ranksfile = $ARGV[1];
if ( ! -e  $ranksfile ) {
    print "$pwd/$ranksfile missing\n";
    next;
} 


open (EPI, "<$epifile") ||
    die "Cno  $epifile: $! \n";
@epitope = ();
$ctr = 0;
while ( <EPI>) {
    if ( /\w/ ) {
	chomp;
	@aux= split;
	$num = $aux[0];
	$epitope [$ctr ] = $num;
	$line [$ctr] = join ' ', @aux;
	$ctr ++;
    }
}
close EPI;


open (RANKS, "<$ranksfile") ||
    die "Cno  $ranksfile: $! \n";

while ( <RANKS> ) {
    next if ( /%/ );
    if ( /\w/ ) {
	chomp;
	@aux = split;
	$pdb2almt{$aux[1]} = $aux[0];
	    
    }
}

close RANKS;


for $ctr( 0 .. $#epitope) {
    $translation = $pdb2almt {$epitope[$ctr] };
    print   "$translation   $line[$ctr]\n";
}
