#! /usr/bin/perl -w 

(defined $ARGV[0]   ) ||
    die "usage: cont_mat.pl  <pdb_name>  \n.";

$pdbfile = $ARGV[0].".pdbq";



open (PDBFILE, "<$pdbfile") ||
    die "could not open $pdbfile.\n";

$ctr = 0;
while ( <PDBFILE> ) {
    if ( ! ( /^ATOM/ || /^HETATM/ ) ){
	next;;
    }
    $atom_number[$ctr] =  substr $_, 6, 5;
    $atom_name[$ctr]  = substr $_, 12, 4;
    $atom_name[$ctr] =~ s/\s//g;
    $atom[$ctr][0]  = substr $_, 30, 8;
    $atom[$ctr][1]  = substr $_, 38, 8;
    $atom[$ctr][2]  = substr $_, 46, 8;
    chomp;
    @aux = split;
    $charge[$ctr] = pop @aux;
    #print "  $atom_number[$ctr]    $atom_name[$ctr]  ";
    #print "$atom[$ctr][0]  $atom[$ctr][1] $atom[$ctr][2]  $charge[$ctr] \n";
    $ctr ++;

}

$no_atoms = $ctr;


for $ctr1 (0 .. ($no_atoms-1) ) {
    for $ctr2 ($ctr1+1  .. ($no_atoms-1) ){
	$r = 0;
	for $i ( 0 ..2) {
	    $a = $atom[$ctr1][$i] - $atom[$ctr2][$i];
	    $r += $a*$a;
	}
	$r = sqrt ($r);
	#print " $ctr1  $atom_name[$ctr1]   $ctr2   $atom_name[$ctr2]  $r ";
	if ( $r < 1.4 ) {
	    if (    (substr $atom_name[$ctr1], 0, 1) =~ "C" && 
		    (substr $atom_name[$ctr2], 0, 1) =~ "H" ) {
		$charge[$ctr1] += $charge[$ctr2];
		$charge[$ctr2] = 100;
	    }
	    if (    (substr $atom_name[$ctr2], 0, 1) =~ "C" && 
		    (substr $atom_name[$ctr1], 0, 1) =~ "H" ) {
		$charge[$ctr2] += $charge[$ctr1];
		$charge[$ctr1] = 100;
		
	    }

	}
	#print "\n";
    }
}


seek PDBFILE, 0, 0;
$ctr = -1;
while ( <PDBFILE> ) {
    next if ( ! /\S/ );
    if ( ! ( /^ATOM/ || /^HETATM/ ) ){
	print;
	next;
    }
    $ctr ++;
    next if ( $charge[$ctr] == 100 );
    chomp;
    $record = substr $_, 0, 6;  $record =~ s/\s//g;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $name = substr $_,  12, 4 ;  $name =~ s/\s//g;
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
    $chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
    $x = substr $_,30, 8;  $x=~ s/\s//g;
    $y = substr $_,38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8; $z=~ s/\s//g;


    if ( length($name) ==4 &&  $name =~ /(..)(\d)(\d)/) {
	$name = $2.$1.$3;; # change name to conform to retarded adt
                         
    }
    if ( (length  $name) == 4 ) {# whoever wrote adt is completely retarded, I swear
	printf  "%-6s%5d %-4s%1s%-3s %1s%4d%1s   %8.3f%8.3f%8.3f", 
	$record,   $serial,  $name,   $alt_loc,   $res_name,
	$chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;
    } else {
	printf  "%-6s%5d  %-3s%1s%-3s %1s%4d%1s   %8.3f%8.3f%8.3f", 
	$record,   $serial,  $name,   $alt_loc,   $res_name,
	$chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;
    }

    if (  length $_ >= 60 ) {
	$occupancy = substr $_, 54, 6;
	if ( $occupancy =~ /\S/)  {
	    printf  "%6.2f",$occupancy
	} else {
	    printf  "%6.2f", 1.0;
	}
    } else {
	printf  "%6.2f", 1.0;
    }
    if (  length $_ >= 66 ) {
	$temp_factor = substr $_, 60, 6;
	if ( $temp_factor =~ /\S/)  {
	    printf  "%6.2f",$temp_factor;
	} else {
	    printf  "%6.2f", 0.0;
	}
    } else {
	printf  "%6.2f", 0.0;
    }

    printf  "%10.3f\n", $charge[$ctr];
}
