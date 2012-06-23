#!/usr/bin/perl -w

##################################################

@color = ("[255,0,0]", "[0,0,255]", "[218,112,214]", "[0,255,0]", "[160,32,240]", "[0,255,255]",
"[64,224,208]", "[165,42,42]", "[255,127,80]", "[255,0,255]", "[255,200,0]", "[135,206,235]",
"[238,130,238]", "[255,215,0]", "[200,50,50]", "[50,50,200]", "[18,112,214]", "[113,255,0]",
"[160,132,140]", "[50,200,200]", "[164,24,108]", "[100,142,255]", "[55,127,180]", "[155,100,255]",
"[155,200,50]", "[135,136,235]", "[138,30,238]", "[155,215,155]","[0,0,0]");
##################################################

(defined $ARGV[0] && defined $ARGV[1]) ||
    die "Usage:  cbc.pl <cluster_file>  <pdb_file_full_path> [<chainname>]\n"; 
 
$pdb_file = $ARGV[1]; 
$cluster_file = $ARGV[0]; 

if ( defined $ARGV[2] ) {
    $chainname =  $ARGV[2];
} else {
    $chainname = "";
}

open ( CLUSTER_FILE, "<$cluster_file") || 
    die "cno $cluster_file\n";

$filename = "";
$home = `pwd`;
chomp $home;

@cluster = (());

$dir = "rasmol_scripts";
if (!  -e $dir) {
    mkdir $dir ||
	die "Could not make $dir directory\n";
}
=pod
$old = $home."/$pdb_file";
$new = $home."/".$dir."/$pdb_file";
  `ln -sf $old $new`;
=cut
TOP: while ( <CLUSTER_FILE> ) {
    next if ( /^\%/ );
    if ( /rank/ || /rho/ ) {
	if ( $filename ) { # existing filename signals that some rank has been read in
	    wrap_up ();    # we have read in all that goes into one file
                           # sort and color the clusters and output the rs file
	    $filename= "";
	    @cluster = (());
	    close FPTR;
	    redo TOP;
	} else {
	    @aux = split ;
	    $filename    = $dir."/".$aux[1].".rs";
	    $cluster_ctr = 0;
	}
	
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
	if ( $chainname) {
	    for $i  (0 .. $#aux) {
		$aux[$i] .= ":$chainname";
	    }
	}
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
wrap_up ();
close CLUSTER_FILE;

##################################################

format FPTR = 
load @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     $pdb_file
restrict protein
wireframe off
backbone 150
color [255,255,255]
background [255,255,255]

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
		#print clusters in the order of decreasing size:
		for ( $cluster_ctr=0; $cluster_ctr<=$#cluster; $cluster_ctr++) {
		    if ( defined $sorted[$cluster_ctr] &&  defined $cluster[$sorted[$cluster_ctr]] ) {
			if ( $sizes{$sorted[$cluster_ctr]} == 1) {
			    $color_index = $#color;
			} else {
			    $color_index = $cluster_ctr;
			}
			@current_cluster =  @{ $cluster[$sorted[$cluster_ctr]]};
			# if there are too many residues per line, 
			# rasmol will not work properly, so split up the
			# residues in sections of 20 residues each
			if ($#current_cluster > 20) {
			    print FPTR "select none\n";
			    while ($#current_cluster > 20) {
				print FPTR "select SELECTED,", join (',' ,  @current_cluster[0..19])," \n";
				splice @current_cluster, 0, 20;
			    }
			    if ( defined $#current_cluster) {
				print FPTR "select SELECTED,", join (',' ,  @current_cluster)," \n";
			    }
			} else {
			    print FPTR "select ", join (',', @current_cluster),"\n";
			}
			print FPTR "color $color[$color_index]\n";
			print FPTR "spacefill\n\n";
		    }
		}
		close FPTR;
	    }
	}


