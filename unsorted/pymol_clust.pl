#!/usr/bin/perl -w
sub wrap_up ();
##################################################
@color = ("[255,0,0]", "[0,0,255]", "[255,255,0]", "[0,255,0]", "[160,32,240]", "[0,255,255]",
       "[64,224,208]",  "[165,42,42]", "[255,127,80]", "[255,0,255]", "[255,160,122]", "[135,206,235]",
       "[238,130,238]", "[255,215,0]", "[255,228,196]", "[132,112,255]", "[18,112,214]", "[188,143,143]",
        "[102,205,170]", "[85,107,47]", "[100,149,237]", "[140,140,140]", "[222,184,135]","[50,205,50]", 
        "[210,180,140]", "[255,140,0]", "[255,20,147]", "[176,48,96]", "[255,235,205]",  "[0,0,0]");
##################################################

( defined $ARGV[1]) ||
    die "Usage:  cbc.pl <cluster_file>  <rank> \n"; 
 
$cluster_file = $ARGV[0]; 
#$pdb_file     = $ARGV[1]; 
$rank         = $ARGV[1];


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
close CLUSTER_FILE;
wrap_up ();
exit 0;

##################################################
=pod
format FPTR = 
load @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     $pdb_file
restrict protein
wireframe off
backbone 150
color [255,255,255]
background [255,255,255]

.
=cut


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
		# open (FPTR, ">$filename") || die "cno $filename\n";
	         #write FPTR ;
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
			if ($#current_cluster > 20) {
			    while ($#current_cluster > 20) {
				print  "show spheres, resid ", join ('+' ,  @current_cluster[0..19])," \n";
				splice @current_cluster, 0, 20;
			    }
			    if ( defined $#current_cluster) {
				print  "show spheres, resid  ", join ('+' ,  @current_cluster)," \n";
			    }
			} else {
			    print  "show spheres, resid ", join ('+', @current_cluster),"\n";
			}
		    }
		}
		close ;
	    }
	}


