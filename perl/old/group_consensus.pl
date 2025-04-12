#! /usr/bin/perl -w

$MIN_RANK =  10;
$MAX_RANK =  15;

(defined $ARGV[1]) ||
    die "\n\tusage: group_consensus.pl <msf file> <groups file> .\n\n";

$msf_file       = $ARGV[0];
$groups_file    = $ARGV[1];


##############################################################
open ( MSF_FILE, "<$msf_file" ) ||
    die "Cno  $msf_file: $!.\n";

    # input sequences
    # format: seq{$name} = "sequence"

while ( <MSF_FILE> ) {
    next if  ( ! /\S/ || /\:/ || /Pile/ || /\/\// );
    chomp;
    @aux = split ;
    if ( !  defined $seq{$aux[0]}   ) {
	$seq{$aux[0]} = "";
    }
    foreach $i ( 1..5 ) {
	if ( defined $aux[$i]) {
	    $seq{$aux[0]} .= $aux[$i];
	}
    }
    
}
$seqlen = length $seq{$aux[0]};
close MSF_FILE;
 


##############################################################
open ( GROUPS_FILE, "<$groups_file" ) ||
    die "Cno  $groups_file: $!.\n";
while ( <GROUPS_FILE>) {
    # input the groups
    # format:  names[rank][group] = "name"
    next if  ( ! /\S/ );
    chomp;
    @aux = split ;
    if ( /rank/) {
	$rank = $aux[1];
	last if ($rank > $MAX_RANK);
    } elsif ( /group/ ) {
	$group = $aux[1];
	$ctr = 0;
    } else {
	$ctr ++;
	$names [$rank][$group][0] = $ctr;
        $names [$rank][$group][$ctr]=$aux[0];
    }

}
close  GROUPS_FILE;
$highest_rank = $rank;
if ($highest_rank < $MAX_RANK ) {
    $MAX_RANK = $highest_rank;
}
##############################################################

foreach $rank ( $MIN_RANK .. $MAX_RANK) {
    print "rank: $rank\n";
    foreach $group ( 1 .. $rank) {
	print "\tgroup: $group  (size ",  $names [$rank][$group][0]," )\n";
	#next if  ( $names [$rank][$group][0] < 3);
	print "\t";
	#foreach $pos ( 0 .. $seqlen-1 ) {
	foreach $pos ( 2 .. 2 ) {
	    %found= ();
SEQ:	    foreach $ctr ( 1 .. $names [$rank][$group][0]) {
		$name = $names [$rank][$group][$ctr];
		@aux = split '', $seq{$name};
		if ( ! defined $found{$aux[$pos]} ) {
		    $found{$aux[$pos]} = 1;
		}else {
		    $found{$aux[$pos]} ++;
		}
	    }
	    $bad = 1;
	    foreach $key  ( keys %found) {
		if ($found{$key} > 0.5*$names [$rank][$group][0]) {
		    $bad = 0;
		    $val = $key;
		    last;
		}
	    }
	    if ( $bad ) {
		print ".";
	    } else {
		print "$val";
	    }
	}
	print "\n";
    }
}

