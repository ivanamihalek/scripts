#! /usr/bin/perl -w

# cut out the piece of structure
# above the plane given by C-alphas
# of the 3 residues given on the command line
#  - used to cross-sec atructures  in pymol

( @ARGV >= 4) ||
    die "Usage:  $0  <pdbfile> <res1> <res2> <res3>\n";


($pdbfile, @res) = @ARGV;

$pdbfile = $ARGV[0];
open (IF, "<$pdbfile" ) 
    || die "Cno $pdbfile: $!.\n";

@resnum = ();
@chain  = ();
foreach $res (@res ) {
    if ( $res =~ ":" ) {
	($num, $chn) = split ":", $res;
    } else {
	($num, $chn) = ( $res, " ");
    }
    push @resnum, $num;
    push @chain, $chn;
}



while ( <IF> ) {
    next if ( !/^ATOM/);
    $chain_id = substr $_, 21, 1;
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $name     = substr $_,  12, 4 ;  $name =~ s/\s//g; 
    for $i (0 ..2) {
	if( $chain_id eq $chain[$i] &&
	    $res_seq  eq $resnum[$i] &&
	    $name eq "CA" ) {
	    $x = substr $_, 30, 8;  $x=~ s/\s//g;
	    $y = substr $_, 38, 8;  $y=~ s/\s//g;
	    $z = substr $_, 46, 8;  $z=~ s/\s//g;
	    @{$coord[$i]} = ($x, $y, $z);
	}
    }

}


@origin =  @{$coord[0]};

for $i (0 ..2) {
    $v1[$i] = $coord[1][$i] - $origin[$i];
    $v2[$i] = $coord[2][$i] - $origin[$i];
}

for $i (0 ..2) {
    $j = ($i+1)%3;
    $k = ($i+2)%3;
    $crossprod[$i] = $v1[$j]*$v2[$k] - $v1[$k]*$v2[$j];
}


seek IF, 0, 0; 

while ( <IF> ) {
    if ( !/^ATOM/  && ! /^HETATM/) {
	print;
	next;
    }
    $point[0] = substr $_, 30, 8;  $point[0]=~ s/\s//g;
    $point[1] = substr $_, 38, 8;  $point[1]=~ s/\s//g;
    $point[2] = substr $_, 46, 8;  $point[2]=~ s/\s//g;

    $dot = 0;
    for $i (0 ..2) {
	$dot +=  ($point[$i] -  $origin[$i])*$crossprod[$i];
    }
    ($dot > 0) && print;
   
}
close IF;
