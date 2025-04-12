#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <pdb trj>  <atom list file>\n";

$filename = $ARGV[1];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

@Res1  = ();
@Res2  = ();
@Atom1 = ();
@Atom2 = ();

while ( <IF> ) {
    chomp;
    ($res1, $atom1, $res2, $atom2) = split;
    push @Res1, $res1;
    push @Res2, $res2;
    push @Atom1, $atom1;
    push @Atom2, $atom2;
}

close IF;

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

while ( <IF> ) {
    if ( /^MODEL\s+(\d+)/ ) {

	$model_no = $1;
	@coords1 = ();
	@coords2 = ();
    } elsif (  /^ENDMDL/ || /^TER/  ) {
	$h_bond_count = 0;
	print "$model_no  ";
	foreach $ctr( 0 ..  $#coords2  ) {
	    @r1 = split " ",  $coords1[$ctr];
	    @r2 = split " ",  $coords2[$ctr];
	    $dist = 0;
	    for $i (0 .. 2 ) {
		$aux = $r1[$i] - $r2[$i];
		$dist += $aux*$aux;
	    }
	    $dist = sqrt ($dist);
	    #printf "\t %s   %s   %8.2f  \n",
	    #$coords1[$ctr], $coords2[$ctr], $dist;
	    printf " %8.2f  ", $dist;
	    ($dist <= 3.2 ) && ($h_bond_count++);
	}
	print " $h_bond_count  \n";
    } elsif ( /^ATOM/ ) {
	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	$name = substr $_,  12, 4;     $name =~ s/\s//g; 
	foreach $ctr( 0 ..  $#Res1  ) {
	    $res = $Res1[$ctr];
	    if ( $res_seq == $res && $name eq $Atom1[$ctr]) {
		$coords1[$ctr] = substr $_,30, 24;
	    }
	}
	foreach $ctr( 0 ..  $#Res2  ) {
	    $res = $Res2[$ctr];
	    if ( $res_seq == $res && $name eq $Atom2[$ctr]) {
		$coords2[$ctr] = substr $_,30, 24;
	    }
	}
    }
}

close IF;

