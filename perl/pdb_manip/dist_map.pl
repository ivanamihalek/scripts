#! /usr/bin/perl -w
# read in PDB file and find a distance map
# for each pair of atoms (to be compare with Pattterson map

use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined $ARGV[0] ) ||
    die "Usage: pdb2seq.pl  <pdbfile>.\n";
$filename =  $ARGV[0];

open ( IF, "<$filename" ) || die "Cno $filename: $!.\n";

$ctr = 0;
while ( <IF> ) {

    last if (  /^ENDMDL/  );
    if ( ! /^ATOM/  ) {
	next;
    }

    if ( $chain ) {
	$chain_name = substr ( $_,  21, 1) ; $chain_name=~ s/\s//g;
	next if ( $chain_name ne $chain );
    }
    
    $line[$ctr] = $_;
    $name = substr $_,  12, 4 ;  $name =~ s/\s//g; 
    $name =~ s/\*//g; 
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_seq  = substr $_, 22, 5;  $res_seq=~ s/\s//g;
    $res_name = substr $_,  17, 4; $res_name=~ s/\s//g;
    $x = substr $_, 30, 8;  $x=~ s/\s//g;
    $y = substr $_, 38, 8;  $y=~ s/\s//g;
    $z = substr $_, 46, 8;  $z=~ s/\s//g;

    
    $atom_coord[$ctr][0] = $x;
    $atom_coord[$ctr][1] = $y;
    $atom_coord[$ctr][2] = $z;

    $ctr ++;

}

close IF;


$n_atoms =$ctr;

@dist = ();
$d_max = -1;
for $i ( 0 .. $n_atoms-1) {
    for $j ( $i+1 .. $n_atoms-1) {

	$d = 0;
	for $x ( 0 .. 2 ) {
	    $aux = $atom_coord[$i][$x] -  $atom_coord[$j][$x];
	    $d += $aux*$aux;
	}
	$d = sqrt $d;

	if ( $d >= 4.5 &&  $d < 5.5 ) {
	    printf " %4d  %4d  %8.2f \n", $i, $j, $d;
	    print $line[$i], $line[$j], "\n";
	}
	
	push @dist, $d;
	( $d > $d_max) && ( $d_max = $d );
	
    }
}

=pod
$max = int ( $d_max );


for $i ( 0 .. $max ) {
    $bin[$i] = 0;
}


D: foreach $d ( @dist ) {

    for $i ( 1 .. $max) {
	if ( $d < $i ) {
	    $bin[$i-1] ++;
	    next D;
	}
    }
}

for $i ( 0 .. $max-1) {
    next if ( !$bin[$i] );

    printf "%4d   %5d\n", $i, $bin[$i];

}
=cut
