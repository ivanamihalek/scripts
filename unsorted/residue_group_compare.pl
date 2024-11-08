#! /usr/bin/perl -w


(defined $ARGV[2]) ||
    die "\n\tusage: residue_group_compare.pl <name> <query_seq_name> <list>.\n\n";

$name      = $ARGV[0];
$query     = $ARGV[1];
$list_file = $ARGV[2];


$ranks_file = $name.".ranks";
$groups_file = $name.".groups";
$msf_file = $name.".pruned.msf";
$path_file = $name.".path";

##############################################################
open ( LIST_FILE, "<$list_file" ) ||
    die "Cno  $list_file: $!.\n";
    # input list of residue numbers (alignment numbers)
while ( <LIST_FILE>) {
    chomp;
    @aux = split;
    push @residues, $aux[0];
}
close  LIST_FILE;

##############################################################
open ( PATH_FILE, "<$path_file" ) ||
    die "Cno  $path_file: $!.\n";
    # input list of residue numbers (alignment numbers)
while ( <PATH_FILE>) {
    next if  ( ! /\S/ );
    chomp;
    @aux = split;
    push @path, $aux[0];
}
close  PATH_FILE;


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
    } elsif ( /group/ ) {
	$group = $aux[1];
	$ctr = 0;
    } else {
        $names [$rank][$group][$ctr]=$aux[0];
	$ctr ++;
    }

}
close  GROUPS_FILE;


##############################################################
open ( RANKS_FILE, "<$ranks_file" ) ||
    die "Cno  $ranks_file: $!.\n";

while ( <RANKS_FILE> ) {
    next if  ( ! /\S/ || /%/ );
    chomp;
    @aux = split ;
    $pdb_no[$aux[0]] = $aux[1];
    $rank_assigned[$aux[0]] = $aux[3];
    $variabl[$aux[0]] = $aux[4];
    $values[$aux[0]]  = $aux[5];
    if ( $aux[1] !~ "-" ) {
	$alig_no[$aux[1]] = $aux[0];
    }
}
close RANKS_FILE;
 

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
close MSF_FILE;
 

foreach $key ( keys %seq ) {
    if ( $key =~ $query ) {
	last;
    }
}


# for each residue from the list
foreach  $residue ( @residues ) {
    # 1) open the file
    $filename   = "residue=$residue".".group_info";
    $res_query  = substr ( $seq{$query}, $residue-1, 1);
    print "$filename; query sequence: $query    query residue : $res_query \n";
    open ( FOUT, ">$filename" ) ||
	die "Cno $filename; $!.\n";
    # 2) print info to the file (seq name residue name, pdb and alignment #
    printf FOUT "\nquery sequence: $query    query residue : $res_query \n";
    printf FOUT "alignement no: $residue   pdb no: $pdb_no[$residue] \n";
    printf FOUT "rank assigned: $rank_assigned[$residue]   variability: $variabl[$residue]    ";
    printf FOUT "values: $values[$residue] \n";
    # 2.5) find number of appearances of each residue
    %pop = ();
    foreach $name ( keys %seq ) {
	$res_value  = substr ( $seq{$name}, $residue-1, 1);
	if ( !defined $pop{$res_value} ) {
	    $pop{$res_value} = 1;
	} else {
	    $pop{$res_value} ++;
	}
    }
    printf FOUT "prominence:  ";
    foreach  $res_value ( keys %pop) {
	print  FOUT "$res_value:$pop{$res_value}  ";
    }
    printf FOUT "\n\n";

    # 3) for each rank of interest:
    foreach $rank ( @path ) {
	next if ($rank==1);
    #    a) output the rank
	printf FOUT "rank %3d: ", $rank;
    #    b) find the group to which the focus seq belongs
	$group =1;
	$ok = 0;
	OUTER: while ( defined $names[$rank][$group] ) {
	    $ctr = 0;
	    while ( defined $names[$rank][$group][$ctr] ) {
		if (  $names[$rank][$group][$ctr] =~ $query ) {
		    $ok = 1;
		    last OUTER;
		}
		$ctr++;
	    }
	    $group++;
	    
	}
	$ok || die "query seq not found; rank $rank\n";

	$group_query = $group;
    #    c) print out 1 if the res is conserved in this group
	$ctr = 0;
	@variability = ();
	%pop = ();
	while ( defined $names[$rank][$group][$ctr] ) {
	    $name =  $names[$rank][$group][$ctr];
	    if ( ! defined   $seq{$name} ) {
		die "Err: *$name* not defined ==> .ranks ==><== .msf\n";
	    }
	    $res_value  = substr ( $seq{$name}, $residue-1, 1);
	    if ( join ('', @variability) !~ $res_value ) {
		push @variability, $res_value;
		$pop{$res_value} = 1;
	    } else {
		$pop{$res_value} ++;
	    }
	    $ctr++;
	}
	foreach  $res_value ( @variability) {
	    print  FOUT "$res_value:$pop{$res_value} ";
	}
    #    d) for all other groups: print all the values appearing in the group
	$group = 1;
        while ( defined $names[$rank][$group] ) {
	    if ( $group >1 && ! ($group%10) ){
		printf  FOUT "\n\t\t";
	    }
	    if ( $group != $group_query) {
		$ctr = 0;
		@variability = ();
		%pop = ();
		while ( defined $names[$rank][$group][$ctr] ) {
		    $name =  $names[$rank][$group][$ctr];
		    if ( ! defined   $seq{$name} ) {
			die "Err: *$name* not defined ==> .ranks ==><== .msf\n";
		    }
		    $res_value  = substr ( $seq{$name}, $residue-1, 1);
		    if ( join ('', @variability) !~ $res_value ) {
			push @variability, $res_value;
			$pop{$res_value} = 1;
		    } else {
			$pop{$res_value} ++;
		    }
		    $ctr++;
		}
		printf  FOUT " | ",;
		foreach  $res_value ( @variability) {
		    print  FOUT  "$res_value:$pop{$res_value} ";
		}
	
	    }
	    $group ++;
	}
	print FOUT  "\n";
    }
    # 4) close the output file
    print FOUT  "\n";
    close FOUT;
}
