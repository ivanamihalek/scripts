#!/usr/bin/perl -w

 

(@ARGV ==2 ) ||
    die "Usage:  $0   <cube score file>   <output name>  \n"; 
($score_file,  $output_file) = @ARGV;



##################################################
# input

open (SCORE_FILE, "<$score_file") || 
    die "cno $score_file\n";

@positions = ();
@aa_types  = ();
@entropies = ();
while ( <SCORE_FILE> ) {
    next if ( !/\S/ );
    next if ( /^#/ );
    @aux = split;
    $pos = shift @aux;
    $aa_type =  shift @aux;
    $entropy =  shift @aux;
    push @positions, $pos;
    push @aa_types, $aa_type;
    push @entropies, $entropy;

    @{$per_pos_info[$pos]} = @aux;

}
$no_nodes = (@aux/5);
close SCORE_FILE;

##################################################
#set the pallette:
( $no_nodes  <= 5) || die "Fix $0: too few colors";

# top node: yellows
@{$node_color[1]} = (255, 255, 0);# bleach by increasing the third index toward 255 
# next node (hopefully, on the path toward the query group)
#     reds
@{$node_color[2]} = (255, 0, 0); # looks like the zeros have to be increased 
                                 # in tandem to make sure it still looks red
#    purple
@{$node_color[3]} = (153, 0, 255);
# blue
@{$node_color[4]} = (0, 255, 0);
# gren
@{$node_color[5]} = (0, 0, 255);




##################################################
# output

# open the output file

($overlap, $entrL, $aaL, $entrR, $aaR) = ();
$ctr = 0;
foreach  $pos  (@positions) {

    
    @aux =  @{$per_pos_info[$pos]};

    foreach $node_ctr ( 1 .. $no_nodes ) {

	@rgb = @{$node_color[$node_ctr]};

	($overlap, $entrL, $aaL, $entrR, $aaR) =  splice @aux, 0, 5;

	$rescale = sprintf "%d", 255*$overlap;
	for $i ( 0 ..2 ) {
	    if ( ! $rgb[$i] ) {
		$rgb[$i] = $rescale;
	    }
	}
	

	$color = join ", ", @rgb; 

	if ( ! ( $ctr % 200 )  ) {
	    $ctr && close FPTR;
	    $filename = $output_file.".$ctr";
	    open (FPTR, ">$filename") || die "cno $filename\n";
	
	}


	print FPTR "Cells($pos, $node_ctr).Select\n";
	print FPTR "With Selection.Interior\n";
	print FPTR "    .Color = RGB( $color )\n";
	print FPTR "    .Pattern = xlSolid\n";
	print FPTR "End With\n";

	$ctr++;
    }
     
}



close FPTR; 





