#! /usr/gnu/bin/perl -w
$cvg = 0.15;
while (<>) {
    chomp;
    open ( INFILE, "<$_" ) || 
	die "cno $_\n";
    $name =$_; 

    while ( <INFILE>) {
	next if /Rank/;
	@aux = split;
	$coverage = $aux[1];
	$overlap  = $aux[ $#aux ];
	last if ($aux[1] > $cvg );
    }
    close INFILE;

    print "   $name:  $coverage  $overlap \n"; 

}
