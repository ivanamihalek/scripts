#! /usr/bin/perl -w

# produce a point a normal, and a vector to
# draw a plane through Ca atoms given on the command line
# (carbon_plane.pl can use it as an input)

sub normalized (@);

@ARGV ||
    die "Usage:  $0  <pdb file>  <3 plane residues> \n";

($pdb, @plane_residues) = @ARGV;


@plane_coords = ();


open (IF, "<$pdb" ) 
    || die "Cno $pdb: $!.\n";
while ( <IF> ) {

    next if ( ! /^ATOM/ );

    $name = substr $_,  12, 4;     $name =~ s/\s//g; 
    next if ($name ne "CA");

    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    foreach $plane_res (@plane_residues) {
	if ( $res_seq == $plane_res) {
	    push @plane_coords , (substr $_,30, 24);
	    last;
	}
    }   
}
close IF;


for $point_ctr (0 ..2) {
    @{$plane_points[$point_ctr]} = split  " ", $plane_coords[$point_ctr];
}
for $i (0 ..2) {
    $vec1[$i] = $plane_points[1][$i] - $plane_points[0][$i];
    $vec2[$i] = $plane_points[2][$i] - $plane_points[0][$i];
}
@vec1 = normalized (@vec1);
@vec2 = normalized (@vec2);

for $i (0 ..2) {
    $j = ($i+1)%3;
    $k = ($i+2)%3;
    $normal[$k] = $vec1[$i]*$vec2[$j] -  $vec1[$j]*$vec2[$i];
}

@normal = normalized (@normal);

printf "origin   %5.2f  %5.2f  %5.2f\n", @{$plane_points[0]};
printf "normal   %5.2f  %5.2f  %5.2f\n", @normal;
printf "x direction   %5.2f  %5.2f  %5.2f\n", @vec2;
`/home/ivanam/perlscr/carbon_plane.pl @normal   @{$plane_points[0]}  @vec2 > carbon_plane.pdb`;


#######################################

sub normalized (@) {
    my @vec_out = @_;
    my $norm;
    my $i;

    $norm = 0;
    for $i (0 .. 2) {
	$norm += $vec_out[$i]*$vec_out[$i];
    }
    $norm = sqrt ($norm);
    # re-normalize
    for $i (0 .. 2) {
	$vec_out[$i] /= $norm;
    }
    
    return @vec_out;
}
