#!/usr/bin/perl -w
sub wrap_up ();

( defined $ARGV[1]) ||
    die "Usage:  cbc.pl <cluster_file>  <rank> \n"; 
 
$cluster_file = $ARGV[0]; 
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

$filename    = "$cluster_file.rank=$rank.rs";
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

    #print clusters in the order of decreasing size:
    for ( $cluster_ctr=0; $cluster_ctr<=$#cluster; $cluster_ctr++) {
	if ( defined $sorted[$cluster_ctr] &&  defined $cluster[$sorted[$cluster_ctr]] ) {
	    if ( $sizes{$sorted[$cluster_ctr]} > 1 ) {
		
		@current_cluster =  @{ $cluster[$sorted[$cluster_ctr]]};
		print  "_", (join "_", @current_cluster), "_\n";
	    }
	}
    }
}

exit 0;
