#! /usr/bin/perl -w
# find box around set of PDB coords - for docking

use IO::Handle;         #autoflush
# FH -> autoflush(1);


(defined $ARGV[0] ) ||
    die "usage: coordbox.pl   <pdbfile>  [<list_of_res>]\n.";

$spacing = 0.15;
$no_points = 126;

$listfile = "";
(defined $ARGV[1])  && ($listfile = $ARGV[1]);
$pdbfile = $ARGV[0];



if ( $listfile ) {
    open (LISTFILE, "<$listfile") ||
	die "could not open $listfile.\n";

    @list = ();
    while ( <LISTFILE>) {
	next if ( ! /\S/);
	@aux = split;
	push @list, $aux[0];
    }
    close LISTFILE;


    open (PDBFILE, "<$pdbfile") ||
	die "could not open $pdbfile.\n";
    $min = ();
    $max = ();
    while ( <PDBFILE> ) {
	next if ( ! /^ATOM/  && !/^HETATM/ );
	next if ( substr ($_, 26, 1) =~ /\S/) ;
	chomp;

	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	$c[0] = substr $_,30, 8;  $c[0]=~ s/\s//g;
	$c[1] = substr $_,38, 8;  $c[1]=~ s/\s//g;
	$c[2] = substr $_, 46, 8; $c[2]=~ s/\s//g;

	for $aa ( @list) {
	    if ( $aa == $res_seq ) {
		if ( ! defined $ctr ) {
		    $ctr = 0;
		    for $ctr(0..2)  {
			$min[$ctr] = $c[$ctr];
			$max[$ctr] = $c[$ctr];
		    }	
		} else {
		    for $ctr(0..2)  {
			if ( $min[$ctr] > $c[$ctr] ) {
			    $min[$ctr] = $c[$ctr];
			}
			if ( $max[$ctr] < $c[$ctr]) {
			    $max[$ctr] = $c[$ctr];
			}
		    }
		}
	    }
	}

    }

    close PDBFILE;

} else { # no list file 

    open (PDBFILE, "<$pdbfile") ||
	die "could not open $pdbfile.\n";
    $min = ();
    $max = ();

    while ( <PDBFILE> ) {
	next if ( ! /^ATOM/  && !/^HETATM/ );
	next if ( substr ($_, 26, 1) =~ /\S/) ;
	chomp;

	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	$c[0] = substr $_,30, 8;  $c[0]=~ s/\s//g;
	$c[1] = substr $_,38, 8;  $c[1]=~ s/\s//g;
	$c[2] = substr $_, 46, 8; $c[2]=~ s/\s//g;

	if ( ! defined $ctr ) {
	    $ctr = 0;
	    for $ctr(0..2)  {
		$min[$ctr] = $c[$ctr];
		$max[$ctr] = $c[$ctr];
	    }	
	} else {
	    for $ctr(0..2)  {
		if ( $min[$ctr] > $c[$ctr] ) {
		    $min[$ctr] = $c[$ctr];
		}
		if ( $max[$ctr] < $c[$ctr]) {
		    $max[$ctr] = $c[$ctr];
		}
	    }
	}

    }

    close PDBFILE;
}







for $ctr (0 ..2 )  {
    $center[$ctr] = ($min[$ctr]+$max[$ctr])/2;
    $spacing =  ($max[$ctr]- $min[$ctr])/$no_points;
    #$no_points = ($max[$ctr]- $min[$ctr])/$spacing;
    print "  $min[$ctr]    $max[$ctr]      center: $center[$ctr]   \n";
    print "      no of points $no_points    spacing  $spacing\n";
    
}	

for $ctr (0 ..2 )  {
    printf " %8.2f ",  $center[$ctr];
}
print "\n";
