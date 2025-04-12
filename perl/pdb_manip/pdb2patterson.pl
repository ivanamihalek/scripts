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
    
    #$line[$ctr] = $_;
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

#@dist = ();
#$d_max = -1;

$max_x = -1;
$max_y = -1;
$max_z = -1;

for $i ( 0 .. $n_atoms-1) {
    for $j ( $i+1 .. $n_atoms-1) {

	$x = int ( $atom_coord[$i][0] -  $atom_coord[$j][0]);
	$y = int ( $atom_coord[$i][1] -  $atom_coord[$j][1]);
	$z = int ( $atom_coord[$i][2] -  $atom_coord[$j][2]);

	$grid{$x}{$y}{$z} ++;

	($max_x < $x ) && ($max_x = $x );
	($max_y < $y ) && ($max_y = $y );
	($max_z < $z ) && ($max_z = $z );
	
    }
}


for ( $x=0; $x <= $max_x; $x++ ) {
    for ( $y=0; $y <= $max_y; $y++ ) {
	for ( $z=0; $z <= $max_z; $z++ ) {

	    $d = sqrt ($x*$x +$y*$y+$z*$z);

	    if ( defined $grid{$x}{$y}{$z} && $grid{$x}{$y}{$z} > 10  ) {
		#printf "%4d  %4d  %4d  %8.2f   %5d\n", $x, $y, $z,  $d, $grid{$x}{$y}{$z} ;
		
		$crap = sprintf  "ATOM  %5d  C   UNK     1", 10000+$ctr;
		printf "%-30s%8.3f%8.3f%8.3f%6.2f%6.2f \n",
		$crap,  $x, $y, $z, 1.0, $grid{$x}{$y}{$z};
	    }
	    
	}
    }
}
