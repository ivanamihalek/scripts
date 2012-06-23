#!/usr/bin/perl -w
sub wrap_up ();

( defined $ARGV[2]) ||
    die "Usage:  cbc.pl <cluster_file>  <pdb_file_full_path>  <rank> [<chainname>]\n"; 

=pod
##################################################
@color_int = ("[255,0,0]", "[0,0,255]", "[255,255,0]", "[0,255,0]", "[160,32,240]", "[0,255,255]", 
       "[64,224,208]",  "[165,42,42]", "[255,127,80]", "[255,0,255]", "[255,160,122]", "[135,206,235]",
       "[238,130,238]", "[255,215,0]", "[255,228,196]", "[132,112,255]", "[18,112,214]", "[188,143,143]",
        "[102,205,170]", "[85,107,47]", "[100,149,237]", "[140,140,140]", "[222,184,135]","[50,205,50]", 
        "[210,180,140]", "[255,140,0]", "[255,20,147]", "[176,48,96]", "[255,235,205]",  "[0,0,0]");

@color = ();
for  $c ( @color_int) {
    $c =~ s/[\[\]]//g;
    @aux = split ',', $c;
    $cnew = "\"[";
    for $i ( 0 .. $#aux ) {
	$aux[$i] =  (int ( $aux[$i]/255*100))/100;
	( $i ) && ($cnew .= ", ");
	$cnew .= "$aux[$i]";
    }
    $cnew .= "]\"";
    print "$cnew,  ";

}
##################################################
=cut

##################################################
@color = ("[1, 0, 0]",  "[0, 0, 1]",  "[1, 1, 0]",  "[0, 1, 0]",  "[0.62, 0.12, 0.94]",  "[0, 1, 1]", 
	  "[0.25, 0.87, 0.81]",  "[0.64, 0.16, 0.16]",  "[1, 0.49, 0.31]",  "[1, 0, 1]",  "[1, 0.62, 0.47]",  
	  "[0.52, 0.8, 0.92]",  "[0.93, 0.5, 0.93]",  "[1, 0.84, 0]",  "[1, 0.89, 0.76]",  "[0.51, 0.43, 1]", 
	  "[0.07, 0.43, 0.83]",  "[0.73, 0.56, 0.56]",  "[0.4, 0.8, 0.66]",  "[0.33, 0.41, 0.18]",  "[0.39, 0.58, 0.92]",
	  "[0.54, 0.54, 0.54]",  "[0.87, 0.72, 0.52]",  "[0.19, 0.8, 0.19]",  "[0.82, 0.7, 0.54]",  "[1, 0.54, 0]", 
	  "[1, 0.07, 0.57]",  "[0.69, 0.18, 0.37]",  "[1, 0.92, 0.8]",  "[0, 0, 0]" );
 
$cluster_file = $ARGV[0]; 
$pdb_file     = $ARGV[1]; 
$rank         = $ARGV[2];

if ( defined $ARGV[3] ) {
    $chainname =  $ARGV[3];
} else {
    $chainname = "";
}

open ( CLUSTER_FILE, "<$cluster_file") || 
    die "cno $cluster_file\n";

$filename = "";
$home = `pwd`;
chomp $home;

@cluster = (());

# find the rank I need
while ( <CLUSTER_FILE> ) {
    next if ( /^\%/ );
    if ( /rank/ ) {
	/rank\:\s+(\d+)/;
	last if ( $rank == $1 );
    }
}

$filename    = "$cluster_file.rank=$rank.pml";
$cluster_ctr = 0;

while ( <CLUSTER_FILE> ) {
    next if ( /^\%/ );
    if ( /rank/ || /rho/ ) {
	last;
    } elsif (/isolated/) {
        $isolated = 1;
    } elsif (/cluster/) {
        $isolated = 0;
	$cluster_ctr++;
	if ( defined $cluster[$cluster_ctr] ) {
	     $cluster[$cluster_ctr] = ();
	}
    } else {
	@aux = split;
	if ( $isolated) {
	    for ($i=0; $i <= $#aux; $i++) {
		$cluster_ctr++;
		if ( defined $cluster[$cluster_ctr] ) {
		    $cluster[$cluster_ctr] = ();
		}
		$cluster[$cluster_ctr][0] = $aux[$i];
	    }
	} else {
	    push @{ $cluster[$cluster_ctr] },  @aux;
	}
	
    }

}
close CLUSTER_FILE;
wrap_up ();
exit 0;

##################################################
format FPTR = 
load @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< , struct_name 
     $pdb_file
zoom complete=1
bg_color white
color white, struct_name
hide lines, struct_name
cartoon tube
show cartoon, struct_name
.



sub wrap_up (){
	    if ( defined @cluster) {
                # sort the clusters by size
		%sizes = ();
		for ( $cluster_ctr=0; $cluster_ctr<=$#cluster; $cluster_ctr++) {
		    if ( defined $cluster[$cluster_ctr] ) {
			$sizes{$cluster_ctr} = $#{$cluster[$cluster_ctr]}+1;
		    }
		}
		@sorted = ();
		@sorted = sort { $sizes{$b} <=> $sizes{$a} } (keys(%sizes)) ;
	        # open the output file
		open (FPTR, ">$filename") || die "cno $filename\n";
	        write FPTR ;
		# color definitions
		for $ctr ( 0 .. $#color ) {
		    print  FPTR "set_color c$ctr = $color[$ctr]\n";
		}

		#print clusters in the order of decreasing size:
		for ( $cluster_ctr=0; $cluster_ctr<=$#cluster; $cluster_ctr++) {
		    if ( defined $sorted[$cluster_ctr] &&  defined $cluster[$sorted[$cluster_ctr]] ) {
			if ( $sizes{$sorted[$cluster_ctr]} == 1 ||  $cluster_ctr >= $#color) {
			    $color_index = $#color;
			} else {
			    $color_index = $cluster_ctr;
			}
			@current_cluster =  @{ $cluster[$sorted[$cluster_ctr]]};
			# if there are too many residues per line, 
			# rasmol will not work properly, so split up the
			# residues in sections of 20 residues each
			$line_ctr = 0;
			if ($#current_cluster > 10) {
			    while ($#current_cluster > 10) {
				$line_ctr ++;
				print FPTR "select sel$line_ctr, resid ";
				print FPTR join ('+' ,  @current_cluster[0..9]);
				if ( $chainname ) {
				    print  FPTR " and chain $chainname";
				} 
				print  FPTR "\n";
				
				splice @current_cluster, 0, 10;
			    }
			    if ( defined $#current_cluster) {
				$line_ctr ++;
				print FPTR "select sel$line_ctr, resid ",  join ('+' ,  @current_cluster);
				if ( $chainname ) {
				    print  FPTR " and chain $chainname";
				} 
				print  FPTR "\n";
			    }
			    $max_line_ctr = $line_ctr;
			    print FPTR "select cluster, sel1";
			    for $line_ctr ( 2 .. $max_line_ctr ) {
				printf FPTR " or sel$line_ctr";
			    }
			    printf FPTR "\n";
			} else {
			    print FPTR "select cluster, resid ";
			    print FPTR  join ('+', @current_cluster);
			    if ( $chainname ) {
				print  FPTR " and chain $chainname";
			    } 
			    print  FPTR "\n";
			}
			print FPTR "color c$color_index, cluster\n";
			print FPTR "show spheres,  cluster\n";
		    }
		}
		close FPTR;
	    }
	}


