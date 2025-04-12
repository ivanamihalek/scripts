#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

( defined $ARGV[1] ) ||
    die "Usage: extr_pos_from_ranks.pl <pos list>  <ranks>.\n";


open ( IF, "<$ARGV[0]" ) ||
    die "Cno  $ARGV[0]: $!.\n";

@positions = ();
while ( <IF> ) {
    chomp; 
    @aux = split;
    push @positions, @aux;
} 

close IF;


$pos = pop @positions;
while ( $pos  ) {
    $line =  `awk \'\$2==$pos {print}\'  $ARGV[1]`;
    @aux = split ' ', $line;
    $cvg = $aux[$#aux-1];
    while ( defined $lines{$cvg} ) {
	$cvg += 1.e-6;
    }
    $lines{$cvg} = $line;
    $pos = pop @positions;
} 
#printf " * \n";
@sorted_cvg = sort ( keys %lines );

foreach $cvg ( @sorted_cvg) {
    #print $lines{$cvg};
    @aux = split " ", $lines{$cvg};
    print "$aux[1] & $aux[2]  & $aux[5]   & $aux[7]  \\\\ \n";
}
