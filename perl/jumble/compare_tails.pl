#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: compare_tails.pl <name_list>\n";


open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";
while ( <NAMES> ) {
   
    if ( /\w/ ) {
	$begin = time;
    
	chomp;
	@aux = split ' ';
	$name = $aux[0];
	$noc = $aux[2];
	$name =~ s/\s//g;
	$query_name =  $name;
	$name1 = "$name.realval.cluster_report.summary";
	$name2 = "$name.entr.cluster_report.summary";
	chdir $name ||
	    die "cn chdir $name: $!\n";
	#qprint "\n $name:\n"; 
	if ( -e $name1 && -e $name2 ) {
	    $line = `grep max $name1`;
	    @line1 = split ' ', $line;
	    $line = `grep max $name2` || "";
	    @line2 = split ' ', $line;
	    printf "%5s  %6d  %8.3e  %8.3e \n", $name, $noc, @line1[2],  @line2[2];
	}
	chdir "../";
    } 
    
}


